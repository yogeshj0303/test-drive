import 'package:flutter/material.dart';

class TestDriveStatusScreen extends StatelessWidget {
  const TestDriveStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Drive Status'),
      ),
      body: const Center(
        child: Text(
          'Test Drive Status Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
} 