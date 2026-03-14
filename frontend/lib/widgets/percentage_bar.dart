import 'package:flutter/material.dart';

class PercentageBar extends StatefulWidget {
  final String label;
  final double percentage;
  final Color color;
  final bool isSelected;
  final bool animate;

  const PercentageBar({
    super.key,
    required this.label,
    required this.percentage,
    required this.color,
    this.isSelected = false,
    this.animate = true,
  });

  @override
  State<PercentageBar> createState() => _PercentageBarState();
}

class _PercentageBarState extends State<PercentageBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _widthAnimation = Tween<double>(
      begin: 0.0,
      end: widget.percentage / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PercentageBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _widthAnimation = Tween<double>(
        begin: _widthAnimation.value,
        end: widget.percentage / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(color: widget.color.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Background
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: _widthAnimation.value,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                // Content
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (widget.isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: widget.color,
                              ),
                            ),
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  widget.isSelected ? FontWeight.bold : FontWeight.w600,
                              color: widget.isSelected
                                  ? widget.color
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: widget.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
