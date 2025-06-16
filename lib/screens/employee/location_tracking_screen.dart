import 'package:flutter/material.dart';

class LocationTrackingScreen extends StatelessWidget {
  const LocationTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
      ),
      body: const Center(
        child: Text(
          'Location Tracking Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
} 