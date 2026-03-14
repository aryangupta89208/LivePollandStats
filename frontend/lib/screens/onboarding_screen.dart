import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_service.dart';
import 'home_screen.dart';
import 'package:uuid/uuid.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  String? _selectedTeam;
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const teams = [
    {'name': 'Chennai Super Kings', 'short': 'CSK', 'color': 0xFFFDB913},
    {'name': 'Mumbai Indians', 'short': 'MI', 'color': 0xFF004BA0},
    {'name': 'Royal Challengers Bengaluru', 'short': 'RCB', 'color': 0xFFEC1C24},
    {'name': 'Kolkata Knight Riders', 'short': 'KKR', 'color': 0xFF3A225D},
    {'name': 'Rajasthan Royals', 'short': 'RR', 'color': 0xFFE73895},
    {'name': 'Sunrisers Hyderabad', 'short': 'SRH', 'color': 0xFFFF822A},
    {'name': 'Delhi Capitals', 'short': 'DC', 'color': 0xFF17479E},
    {'name': 'Punjab Kings', 'short': 'PBKS', 'color': 0xFFED1C24},
    {'name': 'Gujarat Titans', 'short': 'GT', 'color': 0xFF1C1C2B},
    {'name': 'Lucknow Super Giants', 'short': 'LSG', 'color': 0xFF0057E2},
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_selectedTeam == null) return;
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final deviceId = const Uuid().v4();
      final user = await ApiService.signup(deviceId, _selectedTeam!);
      await ApiService.saveDeviceId(deviceId);
      await ApiService.saveUserId(user.id);
      await ApiService.saveTeam(_selectedTeam!);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed. Please try again.\n${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            // Header
            const Text(
              '🏏',
              style: TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            const Text(
              'IPL Fan Battle',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B5E20),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your favorite team',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),

            // Team Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final isSelected = _selectedTeam == team['name'] as String;
                    final color = Color(team['color'] as int);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTeam = team['name'] as String);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                team['short'] as String,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? color : Colors.black87,
                                ),
                              ),
                              Text(
                                team['name'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedTeam != null && !_isLoading ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    disabledBackgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'START PLAYING',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
