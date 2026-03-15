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
  final TextEditingController _nameController = TextEditingController();

  static const teams = [
    {'name': 'Chennai Super Kings', 'image': 'assets/logos/csk.png', 'color': 0xFFFDB913},
    {'name': 'Mumbai Indians', 'image': 'assets/logos/mi.png', 'color': 0xFF004BA0},
    {'name': 'Royal Challengers Bengaluru', 'image': 'assets/logos/rcb.png', 'color': 0xFFEC1C24},
    {'name': 'Kolkata Knight Riders', 'image': 'assets/logos/kkr.png', 'color': 0xFF3A225D},
    {'name': 'Rajasthan Royals', 'image': 'assets/logos/rr.png', 'color': 0xFFE73895},
    {'name': 'Sunrisers Hyderabad', 'image': 'assets/logos/srh.png', 'color': 0xFFFF822A},
    {'name': 'Delhi Capitals', 'image': 'assets/logos/dc.png', 'color': 0xFF17479E},
    {'name': 'Punjab Kings', 'image': 'assets/logos/pbks.png', 'color': 0xFFED1C24},
    {'name': 'Gujarat Titans', 'image': 'assets/logos/gt.png', 'color': 0xFF1C1C2B},
    {'name': 'Lucknow Super Giants', 'image': 'assets/logos/lsg.png', 'color': 0xFF0057E2},
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
      String deviceId = await ApiService.getHardwareId();
      if (deviceId.isEmpty) {
        deviceId = const Uuid().v4();
      }
      
      final nickname = _nameController.text.trim();
      if (nickname.isEmpty) {
        throw Exception('Please enter a nickname to continue');
      }
      if (nickname.length < 3) {
        throw Exception('Nickname must be at least 3 characters');
      }
          
      final user = await ApiService.signup(
        deviceId, 
        _selectedTeam!, 
        displayName: nickname
      );
      
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
            const SizedBox(height: 40),
            // Header
            const Icon(Icons.bolt_rounded, size: 64, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text(
              'IPL Fan Battle',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B5E20),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Choose your favorite team',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            
            // Nickname Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _nameController,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Enter your Nickname (e.g. Dhoni_Fan)',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF2E7D32)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Team Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : Colors.grey.shade100,
                            width: isSelected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                ? color.withValues(alpha: 0.1) 
                                : Colors.black.withValues(alpha: 0.03),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Team Image
                            Container(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                team['image'] as String,
                                height: 64,
                                width: 64,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                team['name'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? color : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                  onPressed: _selectedTeam != null && !_isLoading && _nameController.text.trim().isNotEmpty ? _continue : null,
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
