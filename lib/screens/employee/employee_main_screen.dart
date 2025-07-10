import 'package:flutter/material.dart';
import 'package:varenyam/screens/Employee/add_expense_screen.dart';
import 'employee_home_screen.dart';
import 'assigned_test_drives_screen.dart';
import 'package:varenyam/screens/employee/employee_profile_screen.dart';

class EmployeeMainScreen extends StatefulWidget {
  const EmployeeMainScreen({super.key});

  @override
  State<EmployeeMainScreen> createState() => _EmployeeMainScreenState();
}

class _EmployeeMainScreenState extends State<EmployeeMainScreen> {
  int _currentIndex = 0;
  int _previousIndex = 0;
  final GlobalKey<AssignedTestDrivesScreenState> _assignedTestDrivesKey = GlobalKey<AssignedTestDrivesScreenState>();
  final GlobalKey<State<EmployeeProfileScreen>> _profileScreenKey = GlobalKey<State<EmployeeProfileScreen>>();
  
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const EmployeeHomeScreen(),
      AssignedTestDrivesScreen(key: _assignedTestDrivesKey),
      const AddExpenseScreen(showBackButton: false),
      EmployeeProfileScreen(key: _profileScreenKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            // Check if we're navigating to the Test Drives tab from a different tab
            if (index == 1 && _previousIndex != 1) {
              // Call onScreenVisible method to refresh data
              _assignedTestDrivesKey.currentState?.onScreenVisible();
            }
            
            // Check if we're navigating to the Profile tab from a different tab
            if (index == 3 && _previousIndex != 3) {
              // Call onScreenVisible method to refresh data
              (_profileScreenKey.currentState as dynamic)?.onScreenVisible();
            }
            
            setState(() {
              _currentIndex = index;
              _previousIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3080A5),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Test Drives',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
} 