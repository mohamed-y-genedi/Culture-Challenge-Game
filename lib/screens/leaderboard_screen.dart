import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final SupabaseService _service = SupabaseService();
  List<Map<String, dynamic>>? _leaderboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final data = await _service.getLeaderboard();
    if (mounted) {
      setState(() {
        _leaderboardData = data;
        _isLoading = false;
      });
    }
  }

  Color _getRankColor(int index) {
    if (index == 0) return const Color(0xFFFFD700); // Gold
    if (index == 1) return const Color(0xFFC0C0C0); // Silver
    if (index == 2) return const Color(0xFFCD7F32); // Bronze
    return Colors.white70; // Regular
  }

  IconData _getRankIcon(int index) {
    if (index == 0) return Icons.military_tech;
    if (index == 1) return Icons.workspace_premium;
    if (index == 2) return Icons.workspace_premium;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الشرف 🏆', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _leaderboardData == null || _leaderboardData!.isEmpty
                  ? const Center(child: Text('لا توجد بيانات حتى الآن.', style: TextStyle(fontSize: 18, color: Colors.white70)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListView.builder(
                        itemCount: _leaderboardData!.length,
                        itemBuilder: (context, index) {
                          final player = _leaderboardData![index];
                          final rankColor = _getRankColor(index);
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  index < 3 ? rankColor.withValues(alpha: 0.15) : Theme.of(context).cardColor,
                                  Theme.of(context).cardColor,
                                ],
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: index < 3 ? rankColor.withValues(alpha: 0.5) : Colors.white10,
                                width: index < 3 ? 2 : 1,
                              ),
                              boxShadow: index < 3
                                  ? [
                                      BoxShadow(
                                        color: rankColor.withValues(alpha: 0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: index < 3 ? rankColor.withValues(alpha: 0.2) : Colors.white10,
                                child: index < 3
                                    ? Icon(_getRankIcon(index), color: rankColor, size: 28)
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: rankColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                              title: Text(
                                player['nickname'] ?? 'مجهول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: index < 3 ? Colors.white : Colors.white70,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${player['high_score'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: rankColor,
                                    ),
                                  ),
                                  const Text(
                                    'نقطة',
                                    style: TextStyle(fontSize: 12, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ),
    );
  }
}
