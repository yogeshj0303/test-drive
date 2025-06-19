import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:varenium/screens/employee/location_tracking_screen.dart';
import 'package:varenium/screens/user/user_home_screen.dart';
import 'screens/user/user_login_screen.dart';
import 'screens/employee/employee_login_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const VareniumApp());
}

class VareniumApp extends StatelessWidget {
  const VareniumApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Brand colors
    const Color primaryBlue = Color(0xFF0095D9);
    const Color secondaryBlue = Color(0xFF5D98AF);
    const Color darkGray = Color(0xFF242223);
    return MaterialApp(
      title: 'Varenium',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: secondaryBlue,
          surface: Colors.white,
          background: Colors.white,
          error: Colors.red,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: darkGray,
          onBackground: darkGray,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      // home: LocationSetupPage(key: GlobalKey<LocationSetupPageState>()),
      home: const SplashScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the new brand colors
    const Color primaryBlue = Color(0xFF0095D9);
    const Color secondaryBlue = Color(0xFF5D98AF);
    const Color darkGray = Color(0xFF242223);
    final colorScheme = Theme.of(context).colorScheme;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Container(
          color: Colors.white,
          child: SafeArea(
            child: isLandscape 
                ? _buildLandscapeLayout(context, primaryBlue, secondaryBlue)
                : _buildPortraitLayout(context, primaryBlue, secondaryBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, Color primaryBlue, Color secondaryBlue) {
    return Row(
      children: [
        // Left side - Logo and Features
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Logo in a circle with shadow
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/varenium-removebg-preview.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome to Varenium',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                        const SizedBox(height: 8),
                        Text(
                          'Your trusted platform',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeatureChip(
                        context,
                        icon: Icons.security_rounded,
                        label: 'Secure',
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _buildFeatureChip(
                        context,
                        icon: Icons.speed_rounded,
                        label: 'Fast',
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _buildFeatureChip(
                        context,
                        icon: Icons.support_agent_rounded,
                        label: 'Support',
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right side - Auth Options
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.only(left: 32),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Choose Your Path',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    shadows: [
                      Shadow(
                        color: primaryBlue.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildAuthOption(
                  context,
                  title: 'Continue as User',
                  subtitle: 'Access your dashboard',
                  icon: Icons.person_outline_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                  ),
                  color: primaryBlue,
                ),
                const SizedBox(height: 16),
                _buildAuthOption(
                  context,
                  title: 'Continue as Employee',
                  subtitle: 'Access workspace',
                  icon: Icons.business_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmployeeLoginScreen()),
                  ),
                  color: secondaryBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, Color primaryBlue, Color secondaryBlue) {
    return Column(
      children: [
        // Logo and Title Section
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo in a circle with shadow
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/varenium-removebg-preview.png',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome to Varenium',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                  const SizedBox(height: 4),
                  Text(
                    'Your trusted platform',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
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
                ],
              ),
            ),
          ),
        ),
        // Feature Chips
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureChip(
                context,
                icon: Icons.security_rounded,
                label: 'Secure',
                color: primaryBlue,
              ),
              const SizedBox(width: 8),
              _buildFeatureChip(
                context,
                icon: Icons.speed_rounded,
                label: 'Fast',
                color: secondaryBlue,
              ),
              const SizedBox(width: 8),
              _buildFeatureChip(
                context,
                icon: Icons.support_agent_rounded,
                label: 'Support',
                color: primaryBlue,
              ),
            ],
          ),
        ),
        // Auth Options
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Choose Your Path',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    shadows: [
                      Shadow(
                        color: primaryBlue.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildAuthOption(
                  context,
                  title: 'Continue as User',
                  subtitle: 'Access your dashboard',
                  icon: Icons.person_outline_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                  ),
                  color: primaryBlue,
                ),
                const SizedBox(height: 12),
                _buildAuthOption(
                  context,
                  title: 'Continue as Employee',
                  subtitle: 'Access workspace',
                  icon: Icons.business_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmployeeLoginScreen()),
                  ),
                  color: secondaryBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isDarkBackground = color == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkBackground ? Colors.white.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkBackground ? Colors.white.withOpacity(0.2) : color.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkBackground ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkBackground ? Colors.white : color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: color.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final ColorScheme colorScheme;

  BackgroundPainter(this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.primary.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.25,
        size.width * 0.5,
        size.height * 0.1,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * -0.05,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.75,
        size.width * 0.5,
        size.height * 0.9,
      )
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 1.05,
        0,
        size.height,
      )
      ..close();

    canvas.drawPath(path, paint);

    // Draw decorative circles
    final circlePaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.03)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      size.width * 0.15,
      circlePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.8),
      size.width * 0.2,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
