import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_test_drives_provider.dart';
import '../services/storage_service.dart';
import '../services/employee_storage_service.dart';
import '../screens/user/user_profile_screen.dart';
import '../main.dart';
import '../screens/Employee/employee_login_screen.dart';

class LogoutUtils {
  static final StorageService _storageService = StorageService();

  /// Centralized logout method for users
  static Future<void> performUserLogout(BuildContext context) async {
    if (!context.mounted) return;
    try {
      await _storageService.clearAllData();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Optionally, print error for debugging
      print('Logout error: ' + e.toString());
    }
  }

  /// Centralized logout method for employees
  static Future<void> performEmployeeLogout(BuildContext context) async {
    if (!context.mounted) return;
    try {
      await EmployeeStorageService.clearEmployeeData();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const EmployeeLoginScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // Optionally, print error for debugging
      print('Employee logout error: ' + e.toString());
    }
  }

  /// Show logout confirmation dialog
  static void showLogoutDialog(BuildContext context, {required bool isEmployee}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access your account.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (isEmployee) {
                performEmployeeLogout(context);
              } else {
                performUserLogout(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
} 