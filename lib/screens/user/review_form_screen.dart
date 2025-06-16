import 'package:flutter/material.dart';

class ReviewFormScreen extends StatelessWidget {
  const ReviewFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Test Drive'),
      ),
      body: const Center(
        child: Text(
          'Review Form Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
} 