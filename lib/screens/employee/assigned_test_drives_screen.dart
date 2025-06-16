import 'package:flutter/material.dart';

class AssignedTestDrivesScreen extends StatelessWidget {
  const AssignedTestDrivesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Test Drives'),
      ),
      body: const Center(
        child: Text(
          'Assigned Test Drives Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
} 