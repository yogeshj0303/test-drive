import 'package:flutter/material.dart';

class RequestTestDriveScreen extends StatelessWidget {
  const RequestTestDriveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Test Drive'),
      ),
      body: const Center(
        child: Text(
          'Request Test Drive Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
} 