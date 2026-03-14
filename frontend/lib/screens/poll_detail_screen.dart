import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/poll_model.dart';
import '../widgets/percentage_bar.dart';
import 'package:share_plus/share_plus.dart';

class PollDetailScreen extends StatefulWidget {
  final String pollId;
  final String userId;

  const PollDetailScreen({
    super.key,
    required this.pollId,
    required this.userId,
  });

  @override
  State<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends State<PollDetailScreen>
    with SingleTickerProviderStateMixin {
  PollResult? _result;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final result = await ApiService.getPollResults(
        widget.pollId,
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _share() {
    if (_result == null) return;
    final poll = _result!.poll;
    final breakdown = _result!.teamBreakdown;

    String shareText = '🔥 IPL Fan Battle\n\n';
    shareText += '${poll.question}\n\n';
    shareText += '${poll.optionA}: ${poll.percentageA.toStringAsFixed(0)}%\n';
    shareText += '${poll.optionB}: ${poll.percentageB.toStringAsFixed(0)}%\n\n';

    if (breakdown.isNotEmpty) {
      for (var team in breakdown.take(3)) {
        shareText +=
            '${_getTeamShort(team.team)} fans → ${team.percentageA.toStringAsFixed(0)}% ${poll.optionA}\n';
      }
      shareText += '\n';
    }
    shareText += '🏏 Vote now in IPL Fan Battle!';

    Share.share(shareText);
  }

  @override
  void dispose() {
    _animController.dispose();
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
          'Poll Results',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFFF9A825)),
            onPressed: _share,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : _result == null
              ? const Center(
                  child: Text('Failed to load', style: TextStyle(color: Colors.black54)),
                )
              : FadeTransition(
                  opacity: _slideAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(_slideAnimation),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${_result!.poll.categoryEmoji} ${_result!.poll.categoryLabel}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _result!.poll.question,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${_result!.poll.formattedVotes} votes',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Global Results
                          _sectionTitle('GLOBAL RESULT'),
                          const SizedBox(height: 12),
                          _globalResult(),
                          const SizedBox(height: 28),

                          // Team Breakdown
                          if (_result!.teamBreakdown.isNotEmpty) ...[
                            _sectionTitle('TEAM BREAKDOWN'),
                            const SizedBox(height: 12),
                            ..._result!.teamBreakdown.map(
                              (team) => _teamRow(team),
                            ),
                          ],
                          const SizedBox(height: 32),

                          // Share CTA
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _share,
                              icon: const Icon(Icons.share_rounded),
                              label: const Text(
                                'SHARE RESULTS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF9A825),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade700,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _globalResult() {
    final poll = _result!.poll;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          PercentageBar(
            label: poll.optionA,
            percentage: poll.percentageA,
            color: const Color(0xFF2E7D32),
            isSelected: poll.userVote == 'a',
            animate: true,
          ),
          const SizedBox(height: 16),
          PercentageBar(
            label: poll.optionB,
            percentage: poll.percentageB,
            color: const Color(0xFFC62828),
            isSelected: poll.userVote == 'b',
            animate: true,
          ),
        ],
      ),
    );
  }

  Widget _teamRow(TeamBreakdown team) {
    final teamColor = _getTeamColor(team.team);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                _getTeamShort(team.team),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: teamColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.team,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: team.percentageA / 100,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation(teamColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${team.percentageA.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: teamColor,
                ),
              ),
              Text(
                _result!.poll.optionA,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
