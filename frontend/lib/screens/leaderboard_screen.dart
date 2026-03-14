import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;
  final _periods = ['today', 'week', 'overall'];
  final _periodLabels = ['Today', 'This Week', 'Overall'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadLeaderboard(_periods[_tabController.index]);
      }
    });
    _loadLeaderboard('overall');
  }

  Future<void> _loadLeaderboard(String period) async {
    setState(() => _isLoading = true);
    try {
      final entries = await ApiService.getLeaderboard(period);
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Leaderboard',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey.shade400,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: _periodLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : _entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏆', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'No fans on the board yet!\nBe the first to vote.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: _entries.length,
                  itemBuilder: (_, i) => _leaderboardTile(_entries[i], i),
                ),
    );
  }

  Widget _leaderboardTile(LeaderboardEntry entry, int index) {
    final isTop3 = index < 3;
    final medals = ['🥇', '🥈', '🥉'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isTop3 
            ? _getRankColor(index).withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTop3
              ? _getRankColor(index).withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTop3
                ? Text(medals[index], style: const TextStyle(fontSize: 22))
                : Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 12),
          // Team Badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _getTeamColor(entry.favoriteTeam).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                entry.teamShort,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _getTeamColor(entry.favoriteTeam),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.favoriteTeam} Fan',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.totalVotes} votes • ${entry.accuracy.toStringAsFixed(0)}% accuracy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Fan IQ
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.fanIq}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isTop3
                      ? _getRankColor(index)
                      : const Color(0xFFF9A825),
                ),
              ),
              Text(
                'FAN IQ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFC107);
      case 1:
        return const Color(0xFFB0BEC5);
      case 2:
        return const Color(0xFFFF8A65);
      default:
        return Colors.white54;
    }
  }

  Color _getTeamColor(String team) {
    final map = {
      'Chennai Super Kings': const Color(0xFFFDB913),
      'Mumbai Indians': const Color(0xFF004BA0),
      'Royal Challengers Bengaluru': const Color(0xFFEC1C24),
      'Kolkata Knight Riders': const Color(0xFF3A225D),
      'Rajasthan Royals': const Color(0xFFE73895),
      'Sunrisers Hyderabad': const Color(0xFFFF822A),
      'Delhi Capitals': const Color(0xFF17479E),
      'Punjab Kings': const Color(0xFFED1C24),
      'Gujarat Titans': const Color(0xFF6B7280),
      'Lucknow Super Giants': const Color(0xFF0057E2),
    };
    return map[team] ?? const Color(0xFF4CAF50);
  }
}
