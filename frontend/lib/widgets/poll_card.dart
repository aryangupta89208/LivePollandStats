import 'package:flutter/material.dart';
import '../models/poll_model.dart';
import 'percentage_bar.dart';
import 'vote_button.dart';

class PollCard extends StatefulWidget {
  final PollModel poll;
  final int index;
  final Function(String) onVote;
  final VoidCallback? onTap;

  const PollCard({
    super.key,
    required this.poll,
    required this.index,
    required this.onVote,
    this.onTap,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Staggered entry
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final hasVoted = poll.userVote != null;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasVoted
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5C518).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${poll.categoryEmoji} ${poll.categoryLabel}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5C518),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (hasVoted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: Color(0xFF4CAF50),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'VOTED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4CAF50),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Question
                Text(
                  poll.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Vote buttons or results
                if (hasVoted) ...[
                  PercentageBar(
                    label: poll.optionA,
                    percentage: poll.percentageA,
                    color: const Color(0xFF4CAF50),
                    isSelected: poll.userVote == 'a',
                  ),
                  const SizedBox(height: 10),
                  PercentageBar(
                    label: poll.optionB,
                    percentage: poll.percentageB,
                    color: const Color(0xFFE53935),
                    isSelected: poll.userVote == 'b',
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: VoteButton(
                          label: poll.optionA,
                          color: const Color(0xFF4CAF50),
                          onTap: () => widget.onVote('a'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: VoteButton(
                          label: poll.optionB,
                          color: const Color(0xFFE53935),
                          onTap: () => widget.onVote('b'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Vote count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${poll.formattedVotes} votes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasVoted)
                      Text(
                        'Tap for details →',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
