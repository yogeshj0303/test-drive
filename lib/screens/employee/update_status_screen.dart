import 'package:flutter/material.dart';

class UpdateStatusScreen extends StatelessWidget {
  const UpdateStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Status'),
      ),
      body: const Center(
        child: Text(
          'Update Status Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
} 