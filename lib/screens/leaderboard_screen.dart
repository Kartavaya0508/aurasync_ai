import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  Future<List<Map<String, dynamic>>> _getFullLeaderboard() async {
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
          name = (profileData is List)
              ? profileData[0]['display_name']
              : profileData['display_name'];
        }
        userTotals[name] = (userTotals[name] ?? 0) + (row['eco_points'] as int);
      }

      var sorted = userTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Return top 100
      return sorted
          .take(100)
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
      appBar: AppBar(
        title: const Text(
          "Local Leaderboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getFullLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00E676)),
            );
          }

          final leaders = snapshot.data ?? [];

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.05),
                  border: const Border(
                    bottom: BorderSide(color: Colors.white10, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.group_work_outlined,
                      color: Color(0xFF00E676),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Syncing ${leaders.length} neighbors in your area",
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  itemCount: leaders.length,
                  itemBuilder: (context, i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            leaders[i]['name'] ==
                                "Kartavaya" // Highlight you if needed
                            ? const Color(0xFF00E676).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[900],
                          child: Text(
                            "${i + 1}",
                            style: const TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          leaders[i]['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Text(
                          "${leaders[i]['points']} pts",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
