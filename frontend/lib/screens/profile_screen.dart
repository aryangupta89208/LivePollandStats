import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  UserModel? _user;
  bool _isLoading = true;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final deviceId = await ApiService.getDeviceId();
      if (deviceId != null) {
        final user = await ApiService.getUser(deviceId);
        if (mounted) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
          _animController.forward();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            )
          : _user == null
              ? const Center(
                  child: Text('Unable to load profile',
                      style: TextStyle(color: Colors.white54)),
                )
              : FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _animController,
                    curve: Curves.easeOut,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        // Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getTeamColor(_user!.favoriteTeam),
                                _getTeamColor(_user!.favoriteTeam)
                                    .withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getTeamColor(_user!.favoriteTeam)
                                    .withValues(alpha: 0.3),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _user!.teamShort,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user!.favoriteTeam,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fan since joining 🏏',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                'FAN IQ',
                                _user!.formattedFanIq,
                                '⚡',
                                const Color(0xFFF5C518),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                'VOTES',
                                _user!.totalVotes.toString(),
                                '🗳️',
                                const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                'ACCURACY',
                                '${_user!.accuracy.toStringAsFixed(1)}%',
                                '🎯',
                                const Color(0xFF2196F3),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                'CORRECT',
                                _user!.correctPredictions.toString(),
                                '✅',
                                const Color(0xFF66BB6A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Fan IQ Progress
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Fan IQ Level',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _getFanLevel(_user!.fanIq),
                                    style: const TextStyle(
                                      color: Color(0xFFF5C518),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (_user!.fanIq % 1000) / 1000,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.08),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFF5C518),
                                  ),
                                  minHeight: 10,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_user!.fanIq % 1000}/1000 to next level',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, String emoji, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getFanLevel(int iq) {
    if (iq >= 5000) return '🏆 Legend';
    if (iq >= 3000) return '⭐ Expert';
    if (iq >= 1000) return '🔥 Pro Fan';
    if (iq >= 500) return '👍 Regular';
    return '🌱 Rookie';
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
