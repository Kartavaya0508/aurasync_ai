import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'camera_screen.dart';
import 'swarm_map_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import '../services/notification_service.dart'; // Added Notification Import

class DashboardScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const DashboardScreen({super.key, required this.cameras});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = "User";
  // NEW: Define a community goal for the Solution Challenge
  final double _communityGoalKg = 100.0;

  Future<void> _simulateCollection() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      await supabase
          .from('waste_items')
          .update({'is_collected': true})
          .eq('user_id', user?.id ?? '')
          .eq('is_collected', false);

      // TRIGGER PUSH NOTIFICATION
      await NotificationService.scheduleCollectionAlert();

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("AuraSync: Pickup successful! Points credited."),
            backgroundColor: Color(0xFF00E676),
          ),
        );
      }
    } catch (e) {
      print("Collection Error: $e");
    }
  }

  // UPDATED: Added logic to fetch total community weight for the goal
  Future<Map<String, dynamic>> _getRealImpact() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return {'points': 0, 'kg': "0.00", 'communityTotal': 0.0};

    try {
      // Fetch User Impact
      final response = await supabase
          .from('waste_items')
          .select('eco_points, weight_grams')
          .eq('user_id', user.id)
          .eq('is_collected', true);

      // NEW: Fetch ALL collected waste for community progress
      final communityResponse = await supabase
          .from('waste_items')
          .select('weight_grams')
          .eq('is_collected', true);

      final profileData = await supabase
          .from('profiles')
          .select('display_name')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted && profileData != null) {
        setState(() {
          _userName = profileData['display_name'] ?? "User";
        });
      }

      int totalPoints = 0;
      double totalGrams = 0;
      for (var item in response) {
        totalPoints += (item['eco_points'] as int? ?? 0);
        totalGrams += (item['weight_grams'] as num? ?? 0);
      }

      double communityTotalGrams = 0;
      for (var item in communityResponse) {
        communityTotalGrams += (item['weight_grams'] as num? ?? 0);
      }

      return {
        'points': totalPoints,
        'kg': (totalGrams / 1000).toStringAsFixed(2),
        'communityTotal': communityTotalGrams / 1000,
      };
    } catch (e) {
      print("Error fetching impact: $e");
      return {'points': 0, 'kg': "0.00", 'communityTotal': 0.0};
    }
  }

  Future<List<Map<String, dynamic>>> _getLeaderboard() async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('waste_items')
          .select('eco_points, profiles(display_name)')
          .eq('is_collected', true);

      Map<String, int> userTotals = {};
      for (var row in response) {
        final profileData = row['profiles'];
        String name = "Anonymous";

        if (profileData != null) {
          if (profileData is List && profileData.isNotEmpty) {
            name = profileData[0]['display_name'] ?? "Anonymous";
          } else if (profileData is Map) {
            name = profileData['display_name'] ?? "Anonymous";
          }
        }

        userTotals[name] = (userTotals[name] ?? 0) + (row['eco_points'] as int);
      }

      var sorted = userTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(3)
          .map((e) => {'name': e.key, 'points': e.value})
          .toList();
    } catch (e) {
      print("Leaderboard Error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $_userName!",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        "AuraSync HQ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ).then((_) => setState(() {})),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[900],
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF00E676),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildImpactCard(),
              const SizedBox(height: 30),
              const Text(
                "Operations",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  _buildActionCard(
                    context,
                    title: "Scan Waste",
                    icon: Icons.qr_code_scanner,
                    color: const Color(0xFF00E676),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            CameraScreen(cameras: widget.cameras),
                      ),
                    ).then((_) => setState(() {})),
                  ),
                  const SizedBox(width: 12),
                  _buildActionCard(
                    context,
                    title: "View Swarm",
                    icon: Icons.hub_outlined,
                    color: Colors.blueAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SwarmMapScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildActionCard(
                    context,
                    title: "Pickup",
                    icon: Icons.local_shipping,
                    color: Colors.orangeAccent,
                    onTap: () => _simulateCollection(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildLeaderboardPreview(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Redesigned for Community Impact & Goal tracking (SDG 12)
  Widget _buildImpactCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getRealImpact(),
      builder: (context, snapshot) {
        final int points = snapshot.data?['points'] ?? 0;
        final String kg = snapshot.data?['kg'] ?? "0.00";
        final double communityTotal = snapshot.data?['communityTotal'] ?? 0.0;
        final bool isLoading =
            snapshot.connectionState == ConnectionState.waiting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "COMMUNITY GOAL: SDG 12",
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      letterSpacing: 1.5,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00E676),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                "${communityTotal.toStringAsFixed(1)}kg / ${_communityGoalKg}kg Diverted",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (communityTotal / _communityGoalKg).clamp(0.0, 1.0),
                backgroundColor: Colors.white10,
                color: const Color(0xFF00E676),
                minHeight: 10,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 25),
              const Divider(color: Colors.white10),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your Points",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "$points",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Personal Impact",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "${kg}kg",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  points > 500
                      ? "Level: Eco-Warrior 🛡️"
                      : "Level: Seedling 🌱",
                  style: const TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardPreview() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getLeaderboard(),
      builder: (context, snapshot) {
        final leaders = snapshot.data ?? [];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Local Leaderboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen(),
                      ),
                    ),
                    child: const Text(
                      "See All",
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 30),
              if (leaders.isEmpty)
                const Text(
                  "Collection in progress...",
                  style: TextStyle(color: Colors.grey),
                ),
              for (int i = 0; i < leaders.length; i++)
                _leaderRow(
                  (i + 1).toString(),
                  leaders[i]['name'],
                  "${leaders[i]['points']} pts",
                  isUser: leaders[i]['name'] == _userName,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _leaderRow(
    String rank,
    String name,
    String pts, {
    bool isUser = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            rank,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            name,
            style: TextStyle(
              color: isUser ? const Color(0xFF00E676) : Colors.white,
              fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            pts,
            style: const TextStyle(
              color: Color(0xFF00E676),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
