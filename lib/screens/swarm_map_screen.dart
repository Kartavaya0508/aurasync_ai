import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class SwarmMapScreen extends StatefulWidget {
  const SwarmMapScreen({super.key});

  @override
  State<SwarmMapScreen> createState() => _SwarmMapScreenState();
}

class _SwarmMapScreenState extends State<SwarmMapScreen> {
  final supabase = Supabase.instance.client;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSwarmData();
  }

  Future<void> _fetchSwarmData() async {
    try {
      final List<dynamic> data = await supabase.from('waste_items').select();

      if (data.isNotEmpty) {
        final newMarkers = data.map((item) {
          double lat = (item['location_lat'] ?? 29.9691).toDouble();
          double lng = (item['location_lng'] ?? 76.9629).toDouble();

          // Jitter to prevent overlapping
          final random = math.Random();
          lat += (random.nextDouble() - 0.5) * 0.0004;
          lng += (random.nextDouble() - 0.5) * 0.0004;

          return Marker(
            markerId: MarkerId(item['id'].toString()),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              item['is_toxic'] == true
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(title: item['material_type']),
          );
        }).toSet();

        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(data[0]['location_lat'], data[0]['location_lng']),
              15.0,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Map Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Neighborhood Swarm",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: const CameraPosition(
              target: LatLng(29.9691, 76.9629),
              zoom: 12,
            ),
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF00E676)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hub, color: Color(0xFF00E676)),
                  const SizedBox(width: 12),
                  Text(
                    "Swarm Density: ${_markers.length} items",
                    style: const TextStyle(
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
    );
  }
}
