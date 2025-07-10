// import 'package:flutter/material.dart';
// import '../../models/user_model.dart';
// import '../../services/api_service.dart';
// import '../../services/storage_service.dart';
// import '../../utils/location_data.dart';
// import 'main_user_screen.dart';

// class UserSignupScreen extends StatefulWidget {
//   const UserSignupScreen({super.key});

//   @override
//   State<UserSignupScreen> createState() => _UserSignupScreenState();
// }

// class _UserSignupScreenState extends State<UserSignupScreen> with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _mobileController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _pincodeController = TextEditingController();
  
//   // State and district dropdown variables
//   String? _selectedState;
//   String? _selectedDistrict;
//   List<String> _availableDistricts = [];
  
//   bool _isPasswordVisible = false;
//   bool _isConfirmPasswordVisible = false;
//   bool _isLoading = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;

//   final ApiService _apiService = ApiService();
//   final StorageService _storageService = StorageService();

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1800),
//     );
//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
//       ),
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, 0.1),
//       end: Offset.zero,
//     ).animate(
//       CurvedAnimation(
//         parent: _animationController,
//         curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
//       ),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _mobileController.dispose();
//     _cityController.dispose();
//     _pincodeController.dispose();
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleSignup() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
      
//       try {
//         final signupRequest = SignupRequest(
//           name: _nameController.text.trim(),
//           email: _emailController.text.trim(),
//           password: _passwordController.text,
//           mobile: _mobileController.text.trim(),
//           city: _cityController.text.trim(),
//           state: _selectedState ?? '',
//           district: _selectedDistrict ?? '',
//           pincode: _pincodeController.text.trim(),
//         );

//         final response = await _apiService.signup(signupRequest);
        
//         if (response.success && response.data != null) {
//           // Save user data and token to secure storage
//           await _storageService.saveUser(response.data!);
//           await _storageService.setLoggedIn(true);
          
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Row(
//                   children: [
//                     const Icon(Icons.check_circle, color: Colors.white),
//                     const SizedBox(width: 8),
//                     Expanded(child: Text(response.message)),
//                   ],
//                 ),
//                 backgroundColor: Colors.green,
//                 behavior: SnackBarBehavior.floating,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 duration: const Duration(seconds: 3),
//               ),
//             );
            
//             // Navigate to user home screen
//             Navigator.pushAndRemoveUntil(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const MainUserScreen(),
//               ),
//               (route) => false,
//             );
//           }
//         } else {
//           if (mounted) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Row(
//                   children: [
//                     const Icon(Icons.error, color: Colors.white),
//                     const SizedBox(width: 8),
//                     Expanded(child: Text(response.message)),
//                   ],
//                 ),
//                 backgroundColor: Colors.red,
//                 behavior: SnackBarBehavior.floating,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 duration: const Duration(seconds: 4),
//               ),
//             );
//           }
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const Icon(Icons.error, color: Colors.white),
//                   const SizedBox(width: 8),
//                   Expanded(child: Text('An error occurred: ${e.toString()}')),
//                 ],
//               ),
//               backgroundColor: Colors.red,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               duration: const Duration(seconds: 4),
//             ),
//           );
//         }
//       } finally {
//         if (mounted) {
//           setState(() => _isLoading = false);
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     const Color primaryBlue = Color(0xFF0095D9);
//     const Color darkGray = Color(0xFF242223);

//     return Scaffold(
//       body: Container(
//         color: Colors.white,
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(12),
//               child: Container(
//                 constraints: BoxConstraints(
//                   maxWidth: 500,
//                   maxHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
//                 ),
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: SlideTransition(
//                     position: _slideAnimation,
//                     child: _buildSignupForm(primaryBlue, darkGray),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSignupForm(Color primaryBlue, Color darkGray) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: primaryBlue.withOpacity(0.06),
//             blurRadius: 20,
//             spreadRadius: 2,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Fixed Header Section
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Create Account',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: darkGray,
//                   letterSpacing: 0.3,
//                   height: 1.1,
//                   shadows: [
//                     Shadow(
//                       color: darkGray.withOpacity(0.1),
//                       blurRadius: 3,
//                       offset: const Offset(0, 1),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Join Varenyam today',
//                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                   color: darkGray.withOpacity(0.7),
//                   letterSpacing: 0.2,
//                   height: 1.3,
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//           // Scrollable Form Section
//           Flexible(
//             child: SingleChildScrollView(
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     _buildInputField(
//                       controller: _nameController,
//                       label: 'Full Name',
//                       hint: 'Enter your full name',
//                       prefixIcon: Icons.person_outline,
//                       accentColor: primaryBlue,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your name';
//                         }
//                         if (value.length < 2) {
//                           return 'Name must be at least 2 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInputField(
//                       controller: _emailController,
//                       label: 'Email',
//                       hint: 'Enter your email',
//                       prefixIcon: Icons.email_outlined,
//                       keyboardType: TextInputType.emailAddress,
//                       accentColor: primaryBlue,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your email';
//                         }
//                         if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInputField(
//                       controller: _passwordController,
//                       label: 'Password',
//                       hint: 'Enter your password',
//                       prefixIcon: Icons.lock_outline,
//                       obscureText: !_isPasswordVisible,
//                       accentColor: primaryBlue,
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isPasswordVisible
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                           color: primaryBlue,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _isPasswordVisible = !_isPasswordVisible;
//                           });
//                         },
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your password';
//                         }
//                         if (value.length < 6) {
//                           return 'Password must be at least 6 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInputField(
//                       controller: _confirmPasswordController,
//                       label: 'Confirm Password',
//                       hint: 'Confirm your password',
//                       prefixIcon: Icons.lock_outline,
//                       obscureText: !_isConfirmPasswordVisible,
//                       accentColor: primaryBlue,
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isConfirmPasswordVisible
//                               ? Icons.visibility_outlined
//                               : Icons.visibility_off_outlined,
//                           color: primaryBlue,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
//                           });
//                         },
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please confirm your password';
//                         }
//                         if (value != _passwordController.text) {
//                           return 'Passwords do not match';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInputField(
//                       controller: _mobileController,
//                       label: 'Mobile',
//                       hint: 'Enter your mobile number',
//                       prefixIcon: Icons.phone_outlined,
//                       keyboardType: TextInputType.phone,
//                       accentColor: primaryBlue,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your mobile number';
//                         }
//                         if (value.length < 10) {
//                           return 'Mobile number must be at least 10 digits';
//                         }
//                         if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
//                           return 'Mobile number must contain only digits';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     _buildDropdownField(
//                       label: 'State',
//                       hint: 'Select your state',
//                       prefixIcon: Icons.location_on_outlined,
//                       value: _selectedState,
//                       items: IndianLocation.states,
//                       onChanged: (String? newValue) {
//                         setState(() {
//                           _selectedState = newValue;
//                           _selectedDistrict = null; // Reset district when state changes
//                           _availableDistricts = newValue != null 
//                               ? IndianLocation.getDistricts(newValue)
//                               : [];
//                         });
//                       },
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please select your state';
//                         }
//                         return null;
//                       },
//                       accentColor: primaryBlue,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildDropdownField(
//                       label: 'District',
//                       hint: _selectedState == null ? 'Select state first' : 'Select your district',
//                       prefixIcon: Icons.location_on_outlined,
//                       value: _selectedDistrict,
//                       items: _availableDistricts,
//                       onChanged: _selectedState == null ? null : (String? newValue) {
//                         setState(() {
//                           _selectedDistrict = newValue;
//                         });
//                       },
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please select your district';
//                         }
//                         return null;
//                       },
//                       accentColor: primaryBlue,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInputField(
//                       controller: _cityController,
//                       label: 'City',
//                       hint: 'Enter your city',
//                       prefixIcon: Icons.location_on_outlined,
//                       accentColor: primaryBlue,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your city';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     _buildInputField(
//                       controller: _pincodeController,
//                       label: 'Pincode',
//                       hint: 'Enter your pincode',
//                       prefixIcon: Icons.location_on_outlined,
//                       keyboardType: TextInputType.number,
//                       accentColor: primaryBlue,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your pincode';
//                         }
//                         if (value.length != 6) {
//                           return 'Pincode must be 6 digits';
//                         }
//                         if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
//                           return 'Pincode must contain only digits';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _handleSignup,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryBlue,
//                           foregroundColor: Colors.white,
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                         ),
//                         child: _isLoading
//                             ? const SizedBox(
//                                 height: 18,
//                                 width: 18,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                                 ),
//                               )
//                             : const Text(
//                                 'Sign Up',
//                                 style: TextStyle(
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: 0.3,
//                                 ),
//                               ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Center(
//                       child: _buildLoginSection(accentColor: primaryBlue),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData prefixIcon,
//     bool obscureText = false,
//     Widget? suffixIcon,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//     required Color accentColor,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       style: const TextStyle(
//         fontSize: 16,
//         letterSpacing: 0.3,
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         labelStyle: TextStyle(
//           color: Colors.grey[600],
//           letterSpacing: 0.3,
//         ),
//         hintStyle: TextStyle(
//           color: Colors.grey[400],
//           letterSpacing: 0.3,
//         ),
//         prefixIcon: Icon(
//           prefixIcon,
//           color: accentColor,
//         ),
//         suffixIcon: suffixIcon,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Colors.grey[300]!,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Colors.grey[300]!,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: accentColor,
//             width: 2,
//           ),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Theme.of(context).colorScheme.error,
//           ),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Theme.of(context).colorScheme.error,
//             width: 2,
//           ),
//         ),
//         filled: true,
//         fillColor: Colors.grey[50],
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 14,
//           vertical: 12,
//         ),
//       ),
//       validator: validator,
//     );
//   }

//   Widget _buildLoginSection({required Color accentColor}) {
//     const Color darkGray = Color(0xFF242223);
//     return FittedBox(
//       fit: BoxFit.scaleDown,
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             'Already have an account?',
//             style: TextStyle(
//               color: darkGray.withOpacity(0.7),
//               fontSize: 15,
//               letterSpacing: 0.3,
//             ),
//           ),
//           const SizedBox(width: 4),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             style: TextButton.styleFrom(
//               foregroundColor: accentColor,
//               padding: const EdgeInsets.symmetric(horizontal: 4),
//               minimumSize: Size.zero,
//               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//             ),
//             child: const Text(
//               'Sign In',
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//                 letterSpacing: 0.3,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDropdownField({
//     required String label,
//     required String hint,
//     required IconData prefixIcon,
//     required String? value,
//     required List<String> items,
//     required Function(String?)? onChanged,
//     required String? Function(String?)? validator,
//     required Color accentColor,
//   }) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       items: items.map<DropdownMenuItem<String>>((String value) {
//         return DropdownMenuItem<String>(
//           value: value,
//           child: Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               letterSpacing: 0.3,
//             ),
//           ),
//         );
//       }).toList(),
//       onChanged: onChanged,
//       style: const TextStyle(
//         fontSize: 16,
//         letterSpacing: 0.3,
//         color: Colors.black87,
//       ),
//       icon: Icon(
//         Icons.keyboard_arrow_down,
//         color: accentColor,
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         labelStyle: TextStyle(
//           color: Colors.grey[600],
//           letterSpacing: 0.3,
//         ),
//         hintStyle: TextStyle(
//           color: Colors.grey[400],
//           letterSpacing: 0.3,
//         ),
//         prefixIcon: Icon(
//           prefixIcon,
//           color: accentColor,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Colors.grey[300]!,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Colors.grey[300]!,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: accentColor,
//             width: 2,
//           ),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Theme.of(context).colorScheme.error,
//           ),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(
//             color: Theme.of(context).colorScheme.error,
//             width: 2,
//           ),
//         ),
//         filled: true,
//         fillColor: Colors.grey[50],
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 14,
//           vertical: 12,
//         ),
//       ),
//       validator: validator,
//     );
//   }
// } 