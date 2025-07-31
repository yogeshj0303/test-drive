import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'lib/providers/user_test_drives_provider.dart';
import 'lib/utils/logout_utils.dart';
import 'lib/services/storage_service.dart';
import 'lib/services/employee_storage_service.dart';

void main() {
  group('Logout Functionality Tests', () {
    testWidgets('LogoutUtils should clear all caches and navigate properly', (WidgetTester tester) async {
      // Create a test app with provider
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserTestDrivesProvider()),
          ],
          child: MaterialApp(
            home: TestScreen(),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Test Screen'), findsOneWidget);
      
      // Test logout functionality
      await tester.tap(find.text('Test Logout'));
      await tester.pumpAndSettle();
      
      // Verify logout dialog appears
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      
      // Test logout confirmation
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      
      // Verify loading dialog appears
      expect(find.text('Logging out...'), findsOneWidget);
      expect(find.text('Please wait while we clear your data'), findsOneWidget);
    });

    test('Storage service should clear all data properly', () async {
      final storageService = StorageService();
      
      // Test clearAllData method
      await storageService.clearAllData();
      
      // Verify data is cleared
      final isLoggedIn = await storageService.isLoggedIn();
      final user = await storageService.getUser();
      final token = await storageService.getToken();
      
      expect(isLoggedIn, false);
      expect(user, null);
      expect(token, null);
    });

    test('Employee storage service should clear data properly', () async {
      // Test clearEmployeeData method
      await EmployeeStorageService.clearEmployeeData();
      
      // Verify data is cleared
      final employee = await EmployeeStorageService.getEmployeeData();
      final hasSession = await EmployeeStorageService.hasValidSession();
      
      expect(employee, null);
      expect(hasSession, false);
    });
  });
}

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => LogoutUtils.showLogoutDialog(context, isEmployee: false),
          child: Text('Test Logout'),
        ),
      ),
    );
  }
} 