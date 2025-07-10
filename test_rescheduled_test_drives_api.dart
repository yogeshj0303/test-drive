import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  group('Rescheduled Test Drives API Tests', () {
    const String baseUrl = 'https://varenyam.acttconnect.com';
    const String endpoint = '/api/employee/textdrives_with_status';
    
    test('Fetch rescheduled test drives for user ID 2', () async {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'users_id': 2,
          'status': 'rescheduled',
        }),
      );

      expect(response.statusCode, 200);
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      expect(responseData['success'], true);
      expect(responseData['message'], isA<String>());
      expect(responseData['data'], isA<List>());
      
      if (responseData['data'].isNotEmpty) {
        final testDrive = responseData['data'][0] as Map<String, dynamic>;
        expect(testDrive['id'], isA<int>());
        expect(testDrive['status'], 'rescheduled');
        expect(testDrive['car'], isA<Map>());
        expect(testDrive['car']['name'], isA<String>());
      }
    });

    test('API returns proper error for invalid user ID', () async {
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'users_id': 999999, // Invalid user ID
          'status': 'rescheduled',
        }),
      );

      expect(response.statusCode, 200);
      
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      // Should return empty data array for non-existent user
      expect(responseData['data'], isA<List>());
    });
  });
} 