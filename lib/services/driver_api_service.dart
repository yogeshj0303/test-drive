import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/employee_model.dart';
import '../models/expense_model.dart';
import '../models/test_drive_model.dart';
import '../models/activity_log_model.dart';
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

  Future<EmployeeApiResponse<EmployeeProfileResponse>> getProfile(int employeeId) async {
    try {
      debugPrint('Fetching employee profile for ID: $employeeId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.employeeProfileEndpoint)}/$employeeId');
      
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      debugPrint('Employee profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final profileResponse = EmployeeProfileResponse.fromJson(responseData);
        return EmployeeApiResponse.success(profileResponse, message: 'Profile fetched successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to fetch profile');
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

  Future<EmployeeApiResponse<ExpenseResponse>> submitExpense(ExpenseRequest request) async {
    try {
      debugPrint('Submitting expense for user ID: ${request.userId}');
      debugPrint('Expense data: ${request.toFormData()}');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.expenseEndpoint));
      
      debugPrint('Submit expense URL: $uri');
      
      // Create multipart request for file upload
      final multipartRequest = http.MultipartRequest('POST', uri);
      
      // Add headers
      multipartRequest.headers.addAll({
        'Accept': 'application/json',
      });
      
      // Add text fields
      multipartRequest.fields['user_id'] = request.userId.toString();
      multipartRequest.fields['description'] = request.description;
      multipartRequest.fields['amount'] = request.amount.toString();
      multipartRequest.fields['date'] = request.date;
      multipartRequest.fields['classification'] = request.classification;
      multipartRequest.fields['payment_mode'] = request.paymentMode;
      
      if (request.receiptNo != null && request.receiptNo!.isNotEmpty) {
        multipartRequest.fields['receipt_no'] = request.receiptNo!;
      }
      
      if (request.note != null && request.note!.isNotEmpty) {
        multipartRequest.fields['note'] = request.note!;
      }
      
      // Add proof file if available
      if (request.proofFile != null) {
        final file = request.proofFile!;
        final fileName = file.path.split('/').last;
        final fileExtension = fileName.split('.').last.toLowerCase();
        
        // Determine content type based on file extension
        String contentType;
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
          contentType = 'image/$fileExtension';
        } else if (['mp4', 'avi', 'mov', 'wmv', 'flv'].contains(fileExtension)) {
          contentType = 'video/$fileExtension';
        } else {
          contentType = 'application/octet-stream';
        }
        
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        
        final multipartFile = http.MultipartFile(
          'proof',
          fileStream,
          fileLength,
          filename: fileName,
        );
        
        multipartRequest.files.add(multipartFile);
        debugPrint('Added proof file: $fileName (${fileLength} bytes)');
      }
      
      final streamedResponse = await multipartRequest.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Submit expense response status: ${response.statusCode}');
      debugPrint('Submit expense response data: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final expenseData = responseData['data'] as Map<String, dynamic>;
          final expenseResponse = ExpenseResponse.fromJson(expenseData);
          final message = responseData['message'] as String? ?? 'Expense submitted successfully';
          
          debugPrint('Successfully submitted expense with ID: ${expenseResponse.id}');
          return EmployeeApiResponse.success(expenseResponse, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to submit expense';
          return EmployeeApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to submit expense');
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

  Future<EmployeeApiResponse<AssignedTestDriveResponse>> getAssignedTestDrives(int driverId) async {
    try {
      debugPrint('Fetching assigned test drives for driver ID: $driverId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/driver/assigned/testdrives/list?driver_id=$driverId');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      debugPrint('Assigned test drives response status: ${response.statusCode}');
      debugPrint('Assigned test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final assignedTestDrivesResponse = AssignedTestDriveResponse.fromJson(responseData);
          debugPrint('Successfully fetched ${assignedTestDrivesResponse.data.length} assigned test drives');
          return EmployeeApiResponse.success(assignedTestDrivesResponse, message: assignedTestDrivesResponse.message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch assigned test drives';
          return EmployeeApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to fetch assigned test drives');
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

  Future<EmployeeApiResponse<AssignedTestDriveResponse>> getTestDrivesByStatus(int driverId, String status) async {
    try {
      debugPrint('Fetching test drives for driver ID: $driverId with status: $status');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/driver/testdrives/status?driver_id=$driverId&status=$status');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      debugPrint('Test drives by status response status: ${response.statusCode}');
      debugPrint('Test drives by status response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final assignedTestDrivesResponse = AssignedTestDriveResponse.fromJson(responseData);
          debugPrint('Successfully fetched ${assignedTestDrivesResponse.data.length} test drives with status: $status');
          return EmployeeApiResponse.success(assignedTestDrivesResponse, message: assignedTestDrivesResponse.message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch test drives by status';
          return EmployeeApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        // Handle 404 - No test drives found for this status
        debugPrint('No test drives found for status: $status (404)');
        return EmployeeApiResponse.success(
          AssignedTestDriveResponse(
            success: true,
            message: 'No test drives found for this status',
            data: [],
          ),
          message: 'No test drives found for this status',
        );
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to fetch test drives by status');
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

  Future<EmployeeApiResponse<PerformanceCountResponse>> getPerformanceCount(int driverId) async {
    try {
      debugPrint('Fetching performance count for driver ID: $driverId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/driver/testdrives/performance/count?driver_id=$driverId');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      debugPrint('Performance count response status: ${response.statusCode}');
      debugPrint('Performance count response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final performanceCountResponse = PerformanceCountResponse.fromJson(responseData);
        
        if (performanceCountResponse.success) {
          debugPrint('Successfully fetched performance count: ${performanceCountResponse.data.totalTestdrives} total, ${performanceCountResponse.data.pendingTestdrives} pending, ${performanceCountResponse.data.thisMonthTestdrives} this month');
          return EmployeeApiResponse.success(performanceCountResponse, message: performanceCountResponse.message);
        } else {
          return EmployeeApiResponse.error(performanceCountResponse.message);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to fetch performance count');
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

  Future<EmployeeApiResponse<Map<String, dynamic>>> updateTestDriveStatus({
    required int testDriveId,
    required int driverId,
    required String status,
    String? cancelDescription,
  }) async {
    try {
      debugPrint('Updating test drive status for ID: $testDriveId, Driver ID: $driverId, Status: $status');
      
      // Build query parameters
      final queryParams = {
        'status': status,
        'testdrive_id': testDriveId.toString(),
        'driver_id': driverId.toString(),
      };
      
          // Add cancel_description if status is cancelled
    if (status.toLowerCase() == 'cancelled' && cancelDescription != null && cancelDescription.isNotEmpty) {
        queryParams['cancel_description'] = cancelDescription;
      }
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.testDriveStatusUpdateEndpoint))
          .replace(queryParameters: queryParams);
      
      debugPrint('Update test drive status URL: $uri');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      debugPrint('Update test drive status response status: ${response.statusCode}');
      debugPrint('Update test drive status response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Test drive status updated successfully';
          debugPrint('Successfully updated test drive status to: $status');
          return EmployeeApiResponse.success(responseData, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to update test drive status';
          return EmployeeApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to update test drive status');
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

  Future<EmployeeApiResponse<Map<String, dynamic>>> rescheduleTestDrive({
    required int testDriveId,
    required int driverId,
    required String newDate,
    String? reason,
  }) async {
    try {
      debugPrint('Rescheduling test drive for ID: $testDriveId, Driver ID: $driverId, New Date: $newDate');
      
      // Build query parameters
      final queryParams = {
        'status': 'rescheduled',
        'testdrive_id': testDriveId.toString(),
        'driver_id': driverId.toString(),
        'next_date': newDate,
      };
      
      // Add reason if provided
      if (reason != null && reason.isNotEmpty) {
        queryParams['cancel_description'] = reason;
      }
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.testDriveStatusUpdateEndpoint))
          .replace(queryParameters: queryParams);
      
      debugPrint('Reschedule test drive URL: $uri');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      debugPrint('Reschedule test drive response status: ${response.statusCode}');
      debugPrint('Reschedule test drive response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Test drive rescheduled successfully';
          debugPrint('Successfully rescheduled test drive to: $newDate');
          return EmployeeApiResponse.success(responseData, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to reschedule test drive';
          return EmployeeApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to reschedule test drive');
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

  Future<EmployeeApiResponse<ActivityLogResponse>> getRecentActivities({
    required int userId,
    String userType = 'drivers',
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/activities?user_id=$userId&user_type=$userType',
      );
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final activityLogResponse = ActivityLogResponse.fromJson(responseData);
        if (activityLogResponse.success) {
          return EmployeeApiResponse.success(activityLogResponse, message: activityLogResponse.message);
        } else {
          return EmployeeApiResponse.error(activityLogResponse.message);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return EmployeeApiResponse.error(errorMessage ?? 'Failed to fetch recent activities');
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