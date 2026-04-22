import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'swarm_map_screen.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras[0], ResolutionPreset.low);
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services disabled.');
    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied) return Future.error('Denied');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _saveToSwarm(Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    try {
      Position pos = await _determinePosition();
      await supabase.from('waste_items').insert({
        'user_id': user?.id,
        'material_type': data['item_name'],
        'category': data['category'],
        'analysis_result': data['user_tip'],
        'is_toxic': data['is_toxic'],
        'eco_points': data['eco_points'],
        'weight_grams': data['weight_grams'],
        'location_lat': pos.latitude,
        'location_lng': pos.longitude,
        'is_collected': false, // Points only credit when this becomes true
      });
    } catch (e) {
      print("Save Error: $e");
    }
  }

  Future<void> _analyzeImage(XFile image) async {
    setState(() => _isProcessing = true);
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: String.fromEnvironment(
          'GEMINI_API_KEY',
          defaultValue: 'YOUR_API_KEY_HERE',
        ),
      );
      final imageBytes = await File(image.path).readAsBytes();

      final prompt = TextPart("""
        Identify this waste item for AuraSync.
        Assign 'eco_points' based on impact (5, 20, or 50).
        Provide a realistic 'weight_grams' estimate (e.g. 25 for a blister pack).
        STRICT TOXICITY RULES:
        - Return 'is_toxic: true' for ALL electronics, LED bulbs, batteries, and medical waste (including blister packs).
        - Return 'is_toxic: false' ONLY for general plastic, paper, or organics.

        NEW: 'eco_insight' must be a shocking environmental fact or educational tip 
        about THIS specific item (e.g., "This takes 450 years to decompose" or "Only 9% of this material is successfully recycled globally").
        
        Return ONLY a JSON object in this exact format:
        {
          "item_name": "Short name",
          "category": "E-waste, Plastic, Metal, or Medical",
          "is_toxic": true/false,
          "sdg_impact": "11 or 12",
          "user_tip": "One short, actionable storage tip",
          "eco_insight": "Environmental impact fact",
          "eco_points": 20,
          "weight_grams": 15
        }
      """);

      final content = [
        Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
      ];
      final response = await model.generateContent(content);

      if (response.text != null) {
        final cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        await _saveToSwarm(data);
        if (mounted) _showImpactCard(data);
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showImpactCard(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['item_name'] ?? "Item",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    "+${data['eco_points']} Pts",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: Colors.green[700],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Category: ${data['category']}",
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(color: Colors.white24, height: 30),

            // Eco-Insight Section for Educational Impact
            const Text(
              "Eco-Insight:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00E676),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data['eco_insight'] ??
                  "Every small action counts towards a cleaner planet.",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 15),
            const Text(
              "Safe Disposal Tip:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data['user_tip'] ?? "",
              style: const TextStyle(fontSize: 15, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "Impact: SDG ${data['sdg_impact'] ?? '12'}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Scan Again",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SwarmMapScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "View Swarm",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "AuraSync: Scan Waste",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller)),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00E676), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00E676)),
                    SizedBox(height: 15),
                    Text(
                      "Analyzing & Syncing...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: const Color(0xFF00E676),
        onPressed: () async {
          if (!_isProcessing) {
            final img = await _controller.takePicture();
            await _analyzeImage(img);
          }
        },
        child: const Icon(Icons.qr_code_scanner, size: 40, color: Colors.black),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
