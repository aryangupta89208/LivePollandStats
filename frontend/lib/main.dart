import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/api_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = DevHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const IPLFanBattleApp());
}

class IPLFanBattleApp extends StatelessWidget {
  const IPLFanBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPL Fan Battle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFF9A825),
          surface: Colors.grey.shade50,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        splashColor: const Color(0xFF4CAF50).withValues(alpha: 0.1),
        highlightColor: const Color(0xFF4CAF50).withValues(alpha: 0.05),
      ),
      home: const AppEntry(),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _isLoading = true;
  bool _isOnboarded = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final onboarded = await ApiService.isOnboarded();
    if (mounted) {
      setState(() {
        _isOnboarded = onboarded;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏏', style: TextStyle(fontSize: 56)),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: Color(0xFF2E7D32),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }

    return _isOnboarded ? const HomeScreen() : const OnboardingScreen();
  }
}
