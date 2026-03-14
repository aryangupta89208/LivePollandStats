import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_service.dart';
import '../core/socket_service.dart';
import '../models/poll_model.dart';
import '../widgets/poll_card.dart';
import '../widgets/skeleton_poll_card.dart';
import 'poll_detail_screen.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<PollModel> _polls = [];
  bool _isLoading = true;
  String? _userId;
  String? _userTeam;
  final SocketService _socket = SocketService();
  StreamSubscription? _wsSub;
  final int _currentNavIndex = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    _userId = await ApiService.getUserId();
    _userTeam = await ApiService.getTeam();
    await _loadPolls();
    _connectWs();
  }

  Future<void> _loadPolls() async {
    try {
      final polls = await ApiService.getPolls(userId: _userId);
      if (mounted) {
        setState(() {
          _polls = polls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _connectWs() {
    _socket.connect();
    _wsSub = _socket.stream.listen((data) {
      if (data['type'] == 'vote_update' && mounted) {
        final pollId = data['poll_id'];
        setState(() {
          for (var poll in _polls) {
            if (poll.id == pollId) {
              poll.updateFromWs(data['data']);
              break;
            }
          }
        });
      }
    });
  }

  Future<void> _onVote(PollModel poll, String vote) async {
    if (poll.userVote != null || _userId == null) return;
    HapticFeedback.mediumImpact();

    try {
      final updated = await ApiService.vote(_userId!, poll.id, vote);
      if (mounted) {
        setState(() {
          poll.userVote = vote;
          if (updated != null) {
            poll.votesA = updated.votesA;
            poll.votesB = updated.votesB;
            poll.totalVotes = updated.totalVotes;
            poll.percentageA = updated.percentageA;
            poll.percentageB = updated.percentageB;
          }
        });
        // Navigate to detail
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PollDetailScreen(pollId: poll.id, userId: _userId!),
          ),
        );
      }
    } catch (e) {
      if (mounted && e.toString().contains('Already voted')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You already voted on this poll!')),
        );
      }
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Text('🏏', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IPL Fan Battle',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE POLLS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade600,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_userTeam != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        _getTeamShort(_userTeam!),
                        style: const TextStyle(
                          color: Color(0xFFE65100),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Poll Feed
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: 4,
                      itemBuilder: (_, __) => const SkeletonPollCard(),
                    )
                  : _polls.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🏏', style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 16),
                              Text(
                                'No polls yet!\nCheck back soon.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFF2E7D32),
                          backgroundColor: Colors.white,
                          onRefresh: _loadPolls,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                            itemCount: _polls.length,
                            itemBuilder: (_, i) {
                              return PollCard(
                                poll: _polls[i],
                                index: i,
                                onVote: (vote) => _onVote(_polls[i], vote),
                                onTap: () {
                                  if (_polls[i].userVote != null && _userId != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PollDetailScreen(
                                          pollId: _polls[i].id,
                                          userId: _userId!,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (i) {
            if (i == _currentNavIndex && i == 0) return;
            if (i == 1) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            } else if (i == 2) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            }
          },
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF1B5E20),
          unselectedItemColor: Colors.black87,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          iconSize: 26,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.bolt_rounded),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_rounded),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  String _getTeamShort(String team) {
    final map = {
      'Chennai Super Kings': 'CSK',
      'Mumbai Indians': 'MI',
      'Royal Challengers Bengaluru': 'RCB',
      'Kolkata Knight Riders': 'KKR',
      'Rajasthan Royals': 'RR',
      'Sunrisers Hyderabad': 'SRH',
      'Delhi Capitals': 'DC',
      'Punjab Kings': 'PBKS',
      'Gujarat Titans': 'GT',
      'Lucknow Super Giants': 'LSG',
    };
    return map[team] ?? team;
  }
}
