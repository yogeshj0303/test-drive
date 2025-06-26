import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import 'api_config.dart';

class EmployeeApiService {
  static final EmployeeApiService _instance = EmployeeApiService._internal();
  factory EmployeeApiService() => _instance;
  EmployeeApiService._internal();

  Future<EmployeeApiResponse<EmployeeLoginResponse>> login(String email, String password) async {
    try {
      debugPrint('Attempting employee login for: $email');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.employeeLoginEndpoint));
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('Employee login response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final loginResponse = EmployeeLoginResponse.fromJson(responseData);
        return EmployeeApiResponse.success(loginResponse, message: loginResponse.message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Employee login failed');
      }
    } on SocketException {
      return EmployeeApiResponse.error('Network error: Please check your internet connection');
    } on FormatException {
      return EmployeeApiResponse.error('Invalid response format from server');
    } on TimeoutException {
      return EmployeeApiResponse.error('Request timeout. Please try again.');
    } catch (e) {
      return EmployeeApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<EmployeeApiResponse<EmployeeLoginResponse>> loginWithEmployeeId(String employeeId, String password) async {
    try {
      debugPrint('Attempting employee login with ID: $employeeId');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.employeeLoginEndpoint));
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'employee_id': employeeId,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('Employee login with ID response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final loginResponse = EmployeeLoginResponse.fromJson(responseData);
        return EmployeeApiResponse.success(loginResponse, message: loginResponse.message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Employee login failed');
      }
    } on SocketException {
      return EmployeeApiResponse.error('Network error: Please check your internet connection');
    } on FormatException {
      return EmployeeApiResponse.error('Invalid response format from server');
    } on TimeoutException {
      return EmployeeApiResponse.error('Request timeout. Please try again.');
    } catch (e) {
      return EmployeeApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  String? _extractErrorMessage(String responseBody) {
    try {
      if (responseBody.isEmpty) return 'Empty response from server';
      
      final Map<String, dynamic> errorData = jsonDecode(responseBody);
      
      if (errorData.containsKey('message')) {
        return errorData['message'] as String;
      } else if (errorData.containsKey('error')) {
        return errorData['error'] as String;
      }
      
      return 'Unknown error occurred';
    } catch (e) {
      return 'Failed to parse error response';
    }
  }
} 