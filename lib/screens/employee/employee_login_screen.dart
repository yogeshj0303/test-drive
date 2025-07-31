import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:varenyam/main.dart';
import '../../services/driver_api_service.dart';
import '../../services/employee_storage_service.dart';
import '../../models/employee_model.dart';
import 'employee_main_screen.dart';

class EmployeeLoginScreen extends StatefulWidget {
  const EmployeeLoginScreen({super.key});

  @override
  State<EmployeeLoginScreen> createState() => _EmployeeLoginScreenState();
}

class _EmployeeLoginScreenState extends State<EmployeeLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final employeeId = _employeeIdController.text.trim();
        final password = _passwordController.text;
        
        // Try login with employee ID first, then with email
        EmployeeApiResponse<EmployeeLoginResponse> response;
        
        // Check if employeeId looks like an email
        if (employeeId.contains('@')) {
          response = await EmployeeApiService().login(employeeId, password);
        } else {
          response = await EmployeeApiService().loginWithEmployeeId(employeeId, password);
        }
        
        if (response.success && response.data != null) {
          // Save employee data to local storage
          await EmployeeStorageService.saveEmployeeData(response.data!);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(response.message)),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Navigate to employee main screen after successful login
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const EmployeeMainScreen(),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text(response.message)),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('An error occurred: ${e.toString()}')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    // Define the brand colors from the logo
    const Color primaryBlue = Color(0xFF3080A5); // Secondary blue from logo for employee portal
    const Color secondaryBlue = Color(0xFF0095D9); // Primary blue from logo
    const Color darkGray = Color(0xFF1D1B1C); // Dark gray from logo

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
        return false;
      },
      child: AnnotatedRegion(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: Stack(
            children: [
              Container(
                color: Colors.white,
                child: SafeArea(
                  child: Center(
                    child: isSmallScreen
                        ? _buildMobileLayout(size, primaryBlue)
                        : _buildDesktopLayout(size, primaryBlue),
                  ),
                ),
              ),
              // Back button positioned at top left
              Positioned(
                top: MediaQuery.of(context).padding.top + 30,
                left: 18,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const AuthScreen(),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Size size, Color primaryBlue) {
    const Color secondaryBlue = Color(0xFF0095D9);
    const Color darkGray = Color(0xFF1D1B1C);
    
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 850, // Further reduced from 900
          minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            // Left side - Branding
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: size.height * 0.015, // Further reduced from 0.02
                  horizontal: 20, // Further reduced from 24
                ),
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20), // Further reduced from 25
                    bottomRight: Radius.circular(20), // Further reduced from 25
                  ),
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: size.height * 0.12, // Increased from 0.06 for better visibility
                        child: _buildLogo(),
                      ),
                      SizedBox(height: size.height * 0.015), // Further reduced from 0.02
                      Text(
                        'Employee Portal',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          height: 1.1, // Further reduced from 1.2
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.008), // Further reduced from 0.01
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16), // Further reduced from 20
                        child: Text(
                          'Access your employee dashboard',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.3,
                            height: 1.3, // Further reduced from 1.4
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: size.height * 0.015), // Further reduced from 0.02
                      _buildFeatureList(),
                      SizedBox(height: size.height * 0.02), // Further reduced from 0.025
                      _buildTrustIndicators(),
                    ],
                  ),
                ),
              ),
            ),
            // Right side - Login Form
            Expanded(
              flex: 1,
              child: Container(
                height: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 24, // Further reduced from 28
                  vertical: size.height * 0.015, // Further reduced from 0.02
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildLoginForm(primaryBlue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(Size size, Color primaryBlue) {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: size.height * 0.02, // Further reduced from 0.025
                horizontal: 14, // Further reduced from 16
              ),
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20), // Further reduced from 25
                  bottomRight: Radius.circular(20), // Further reduced from 25
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 12, // Further reduced from 15
                    offset: const Offset(0, 3), // Further reduced from 4
                  ),
                ],
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: size.height * 0.12, // Increased from 0.06 for better visibility
                      child: _buildLogo(),
                    ),
                    SizedBox(height: size.height * 0.012), // Further reduced from 0.015
                    Text(
                      'Employee Portal',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: size.height * 0.006), // Further reduced from 0.008
                    Text(
                      'Access your employee dashboard',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: size.height * 0.012), // Further reduced from 0.015
                    // Add feature highlights for mobile
                    _buildMobileFeatureHighlights(),
                  ],
                ),
              ),
            ),
            // Login Form Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14, // Further reduced from 16
                vertical: size.height * 0.015, // Further reduced from 0.02
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildLoginForm(primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Hero(
      tag: 'employee_logo',
      child: Container(
        padding: const EdgeInsets.all(16), // Increased from 10 for better logo visibility
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.15),
              blurRadius: 20, // Increased from 16 for better shadow effect
              spreadRadius: 2, // Increased from 1.5 for better shadow effect
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/varenium-removebg-preview.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildLoginForm(Color primaryBlue) {
    const Color darkGray = Color(0xFF1D1B1C);
    
    return Container(
      padding: const EdgeInsets.all(16), // Further reduced from 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // Further reduced from 16
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 16, // Further reduced from 20
            spreadRadius: 1.5, // Further reduced from 2
            offset: const Offset(0, 2), // Further reduced from 3
          ),
        ],
        border: Border.all(
          color: primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed Header Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 2.5, // Further reduced from 3
                    height: 18, // Further reduced from 20
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8), // Further reduced from 10
                  Expanded(
                    child: Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: darkGray,
                        letterSpacing: 0.5,
                        height: 1.1, // Further reduced from 1.2
                        shadows: [
                          Shadow(
                            color: darkGray.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2), // Further reduced from 3
              Padding(
                padding: const EdgeInsets.only(left: 10), // Further reduced from 13
                child: Text(
                  'Sign in to your employee account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: darkGray.withOpacity(0.8),
                    letterSpacing: 0.3,
                    height: 1.3, // Further reduced from 1.4
                  ),
                ),
              ),
              const SizedBox(height: 16), // Further reduced from 20
            ],
          ),
          // Form Section
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(
                  controller: _employeeIdController,
                  label: 'Employee ID / Email',
                  hint: 'Enter your employee ID or email',
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.emailAddress,
                  accentColor: primaryBlue,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    // Only check for email format
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12), // Further reduced from 14
                _buildInputField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: !_isPasswordVisible,
                  accentColor: primaryBlue,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: primaryBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12), // Further reduced from 14
                SizedBox(
                  width: double.infinity,
                  height: 40, // Further reduced from 42
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Further reduced from 12
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8), // Further reduced from 10
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 14, // Further reduced from 16
                            width: 14, // Further reduced from 16
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 14, // Further reduced from 15
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required Color accentColor,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 13, // Further reduced from 14
        letterSpacing: 0.3,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          letterSpacing: 0.3,
          fontSize: 12, // Further reduced from 13
        ),
        hintStyle: TextStyle(
          color: Colors.grey[400],
          letterSpacing: 0.3,
          fontSize: 12, // Further reduced from 13
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: accentColor,
          size: 16, // Further reduced from 18
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Further reduced from 10
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Further reduced from 10
          borderSide: BorderSide(
            color: Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Further reduced from 10
          borderSide: BorderSide(
            color: accentColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Further reduced from 10
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Further reduced from 10
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 8, // Further reduced from 10
          vertical: 8, // Further reduced from 10
        ),
        isDense: true,
      ),
      validator: validator,
    );
  }

  Widget _buildFeatureList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildFeatureItem(Icons.security, 'Secure Access'),
          const SizedBox(height: 10),
          _buildFeatureItem(Icons.work_outline, 'Employee Dashboard'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFeatureHighlights() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildFeatureItem(Icons.security, 'Secure Access'),
          const SizedBox(height: 6),
          _buildFeatureItem(Icons.work_outline, 'Employee Dashboard'),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Column(
      children: [
        Text(
          'Streamlining employee management',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 13, // Reduced from 14
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10), // Reduced from 12
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrustIndicator(Icons.security, 'Security'),
            const SizedBox(width: 16), // Reduced from 20
            _buildTrustIndicator(Icons.work, 'Workflow'),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustIndicator(IconData icon, String text) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 16, // Reduced from 18
        ),
        const SizedBox(height: 3), // Reduced from 4
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11, // Reduced from 12
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 