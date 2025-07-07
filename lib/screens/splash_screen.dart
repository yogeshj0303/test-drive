import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/employee_storage_service.dart';
import '../main.dart';
import 'user/main_user_screen.dart';
import 'employee/employee_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Check auto-login status after animation
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      // Wait for animation to complete
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // Check if user has a valid session
        final hasUserSession = await _storageService.hasValidSession();
        final hasEmployeeSession = await EmployeeStorageService.hasValidSession();
        
        debugPrint('Auto-login check: hasUserSession=$hasUserSession, hasEmployeeSession=$hasEmployeeSession');
        
        if (hasUserSession) {
          // User has valid session, get user data
          final user = await _storageService.getUser();
          if (user != null) {
            debugPrint('Auto-login successful for user: ${user.name}');
            
            // Navigate to user home screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const MainUserScreen()),
            );
            return;
          }
        }
        
        if (hasEmployeeSession) {
          // Employee has valid session, get employee data
          final employee = await EmployeeStorageService.getEmployeeData();
          if (employee != null) {
            debugPrint('Auto-login successful for employee: ${employee.name}');
            
            // Navigate to employee main screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const EmployeeMainScreen()),
            );
            return;
          }
        }
        
        // No valid session found, navigate to auth screen
        debugPrint('No valid session found, navigating to auth screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      debugPrint('Auto-login check error: $e');
      // On error, navigate to auth screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0095D9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo in a circle with shadow
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/varenium-removebg-preview.png',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Varenyam',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: primaryBlue.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Trusted Platform',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: primaryBlue.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 