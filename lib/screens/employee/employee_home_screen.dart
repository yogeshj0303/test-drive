import 'package:flutter/material.dart';
import 'assigned_test_drives_screen.dart';
import 'update_status_screen.dart';
import 'add_expense_screen.dart';
import 'location_tracking_screen.dart';

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Implement logout functionality
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildNavigationCard(
              context,
              'Assigned Test Drives',
              Icons.directions_car,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssignedTestDrivesScreen(),
                ),
              ),
            ),
            _buildNavigationCard(
              context,
              'Update Status',
              Icons.update,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdateStatusScreen(),
                ),
              ),
            ),
            _buildNavigationCard(
              context,
              'Add Expense',
              Icons.receipt_long,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddExpenseScreen(),
                ),
              ),
            ),
            _buildNavigationCard(
              context,
              'Location Tracking',
              Icons.location_on,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LocationTrackingScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 