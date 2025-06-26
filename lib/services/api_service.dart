import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/showroom_model.dart';
import '../models/car_model.dart';
import '../models/test_drive_model.dart';
import '../models/review_model.dart' as review;
import 'api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Future<ApiResponse<User>> signup(SignupRequest request) async {
    try {
      debugPrint('Attempting signup for: \\${request.email}');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.signupEndpoint)).replace(queryParameters: request.toJson().map((k, v) => MapEntry(k, v.toString())));
      final response = await http.post(
        uri,
        headers: {'Accept': 'application/json'},
      );

      debugPrint('Signup response status: \\${response.statusCode}');
      debugPrint('Signup response data: \\${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(responseData);
        debugPrint('Signup successful for user: \\${user.name}');
        return ApiResponse.success(user, message: ApiConfig.signupSuccessMessage);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Signup failed');
      }
    } on SocketException {
      debugPrint('Signup network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Signup format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Signup unexpected error: \\${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: \\${e.toString()}');
    }
  }

  Future<ApiResponse<LoginResponse>> login(String emailOrMobile, String password) async {
    try {
      debugPrint('Attempting login for: $emailOrMobile');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.loginEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email_or_mobile': emailOrMobile,
          'password': password,
        }),
      );

      debugPrint('Login response status: ${response.statusCode}');
      debugPrint('Login response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final loginResponse = LoginResponse.fromJson(responseData);
        debugPrint('Login successful for user: ${loginResponse.user.name}');
        return ApiResponse.success(loginResponse, message: loginResponse.message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Login failed');
      }
    } on SocketException {
      debugPrint('Login network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Login format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Login unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<Showroom>>> getShowrooms() async {
    try {
      debugPrint('Fetching showrooms from API');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.showroomsEndpoint));
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Showrooms response status: ${response.statusCode}');
      debugPrint('Showrooms response data: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body) as List<dynamic>;
        final showrooms = responseData.map((json) => Showroom.fromJson(json)).toList();
        debugPrint('Successfully fetched ${showrooms.length} showrooms');
        return ApiResponse.success(showrooms, message: 'Showrooms fetched successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch showrooms');
      }
    } on SocketException {
      debugPrint('Showrooms network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Showrooms format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Showrooms unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<Showroom>>> getNearbyShowrooms(String pincode) async {
    try {
      debugPrint('Fetching nearby showrooms for pincode: $pincode');
      
      // Validate pincode
      if (pincode.isEmpty) {
        debugPrint('Error: Pincode is empty');
        return ApiResponse.error('Invalid pincode provided');
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/near-showrooms?pincode=$pincode');
      debugPrint('Nearby showrooms API URL: $uri');
      
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Nearby showrooms API timeout');
          throw TimeoutException('Request timeout', const Duration(seconds: 30));
        },
      );

      debugPrint('Nearby showrooms response status: ${response.statusCode}');
      debugPrint('Nearby showrooms response headers: ${response.headers}');
      debugPrint('Nearby showrooms response data: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response body is empty
        if (response.body.isEmpty) {
          debugPrint('Nearby showrooms response body is empty');
          return ApiResponse.success([], message: 'No nearby showrooms found');
        }
        
        try {
          final dynamic responseData = jsonDecode(response.body);
          
          // Handle different response formats
          List<dynamic> showroomsList;
          if (responseData is List) {
            showroomsList = responseData;
          } else if (responseData is Map && responseData.containsKey('data')) {
            showroomsList = responseData['data'] as List<dynamic>;
          } else {
            debugPrint('Unexpected response format: $responseData');
            return ApiResponse.error('Unexpected response format from server');
          }
          
          final showrooms = showroomsList.map((json) {
            try {
              return Showroom.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('Error parsing showroom JSON: $json, Error: $e');
              rethrow;
            }
          }).toList();
          
          debugPrint('Successfully fetched ${showrooms.length} nearby showrooms');
          return ApiResponse.success(showrooms, message: 'Nearby showrooms fetched successfully');
        } catch (e) {
          debugPrint('Error parsing nearby showrooms response: $e');
          return ApiResponse.error('Error parsing response: ${e.toString()}');
        }
      } else if (response.statusCode == 404) {
        debugPrint('No nearby showrooms found for pincode: $pincode');
        return ApiResponse.success([], message: 'No nearby showrooms found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        debugPrint('Nearby showrooms API error: $errorMessage');
        return ApiResponse.error(errorMessage ?? 'Failed to fetch nearby showrooms (Status: ${response.statusCode})');
      }
    } on SocketException catch (e) {
      debugPrint('Nearby showrooms network error: ${e.toString()}');
      return ApiResponse.error('Network error: Please check your internet connection');
    } on FormatException catch (e) {
      debugPrint('Nearby showrooms format error: ${e.toString()}');
      return ApiResponse.error('Invalid response format from server');
    } on TimeoutException catch (e) {
      debugPrint('Nearby showrooms timeout error: ${e.toString()}');
      return ApiResponse.error('Request timeout: Please try again');
    } catch (e) {
      debugPrint('Nearby showrooms unexpected error: ${e.toString()}');
      debugPrint('Error type: ${e.runtimeType}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<Car>>> getCarsByShowroom(int showroomId) async {
    try {
      debugPrint('Fetching cars for showroom ID: $showroomId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.carsByShowroomEndpoint)}?showroom_id=$showroomId');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Cars response status: ${response.statusCode}');
      debugPrint('Cars response data: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body) as List<dynamic>;
        final cars = responseData.map((json) => Car.fromJson(json)).toList();
        debugPrint('Successfully fetched ${cars.length} cars for showroom $showroomId');
        return ApiResponse.success(cars, message: 'Cars fetched successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch cars');
      }
    } on SocketException {
      debugPrint('Cars network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Cars format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Cars unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<User>> getUserProfile(int userId) async {
    try {
      debugPrint('Fetching user profile for user ID: $userId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.userProfileEndpoint)}/$userId');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('User profile response status: ${response.statusCode}');
      debugPrint('User profile response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(responseData);
        debugPrint('Successfully fetched user profile for user $userId');
        return ApiResponse.success(user, message: 'User profile fetched successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch user profile');
      }
    } on SocketException {
      debugPrint('User profile network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User profile format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User profile unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<User>> updateUserProfile(int userId, Map<String, dynamic> updateData) async {
    try {
      debugPrint('Updating user profile for user ID: $userId');
      debugPrint('Update data: $updateData');
      
      // Build query parameters
      final queryParams = <String, String>{};
      updateData.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          queryParams[key] = value.toString();
        }
      });
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.updateUserProfileEndpoint)}/$userId')
          .replace(queryParameters: queryParams);
      
      debugPrint('Update URL: $uri');
      
      final response = await http.put(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Update user profile response status: ${response.statusCode}');
      debugPrint('Update user profile response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final user = User.fromJson(responseData);
        debugPrint('Successfully updated user profile for user $userId');
        return ApiResponse.success(user, message: 'User profile updated successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to update user profile');
      }
    } on SocketException {
      debugPrint('Update user profile network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Update user profile format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Update user profile unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> changePassword(int userId, String currentPassword, String newPassword) async {
    try {
      debugPrint('Changing password for user ID: $userId');
      
      // Build query parameters
      final queryParams = <String, String>{
        'user_id': userId.toString(),
        'current_password': currentPassword,
        'new_password': newPassword,
      };
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.changePasswordEndpoint))
          .replace(queryParameters: queryParams);
      
      debugPrint('Change password URL: $uri');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Change password response status: ${response.statusCode}');
      debugPrint('Change password response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = responseData['message'] as String? ?? 'Password changed successfully';
        debugPrint('Successfully changed password for user $userId');
        return ApiResponse.success(message, message: message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to change password');
      }
    } on SocketException {
      debugPrint('Change password network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Change password format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Change password unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<TestDriveResponse>> requestTestDrive(TestDriveRequest request) async {
    try {
      debugPrint('Submitting test drive request for car ID: ${request.carId}');
      debugPrint('Request data: ${request.toJson()}');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.testDriveStoreEndpoint))
          .replace(queryParameters: request.toQueryParameters());
      
      debugPrint('Test drive request URL: $uri');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Test drive request response status: ${response.statusCode}');
      debugPrint('Test drive request response data: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final testDriveData = responseData['data'] as Map<String, dynamic>;
          final testDriveResponse = TestDriveResponse.fromJson(testDriveData);
          final message = responseData['message'] as String? ?? 'Test drive request submitted successfully';
          
          debugPrint('Successfully submitted test drive request with ID: ${testDriveResponse.id}');
          return ApiResponse.success(testDriveResponse, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to submit test drive request';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to submit test drive request');
      }
    } on SocketException {
      debugPrint('Test drive request network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Test drive request format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Test drive request unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<TestDriveListResponse>>> getUserTestDrives(int userId) async {
    try {
      debugPrint('Fetching test drives for user ID: $userId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.userTestDrivesEndpoint)}/$userId');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('User test drives response status: ${response.statusCode}');
      debugPrint('User test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Test drives fetched successfully';
          
          debugPrint('Successfully fetched ${testDrives.length} test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch test drives';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch test drives');
      }
    } on SocketException {
      debugPrint('User test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User test drives unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<TestDriveListResponse>>> getUserPendingTestDrives(int userId) async {
    try {
      debugPrint('Fetching pending test drives for user ID: $userId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.userPendingTestDrivesEndpoint)}/$userId/pending');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('User pending test drives response status: ${response.statusCode}');
      debugPrint('User pending test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Pending test drives fetched successfully';
          
          debugPrint('Successfully fetched ${testDrives.length} pending test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch pending test drives';
          return ApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        debugPrint('No pending test drives found for user $userId (404)');
        return ApiResponse.success([], message: 'No pending test drives found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch pending test drives');
      }
    } on SocketException {
      debugPrint('User pending test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User pending test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User pending test drives unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<TestDriveListResponse>>> getUserCanceledTestDrives(int userId) async {
    try {
      debugPrint('Fetching canceled test drives for user ID: $userId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.userCanceledTestDrivesEndpoint)}/$userId/canceled');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('User canceled test drives response status: ${response.statusCode}');
      debugPrint('User canceled test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Canceled test drives fetched successfully';
          
          debugPrint('Successfully fetched ${testDrives.length} canceled test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch canceled test drives';
          return ApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        debugPrint('No canceled test drives found for user $userId (404)');
        return ApiResponse.success([], message: 'No canceled test drives found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch canceled test drives');
      }
    } on SocketException {
      debugPrint('User canceled test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User canceled test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User canceled test drives unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<TestDriveListResponse>>> getUserCompletedTestDrives(int userId) async {
    try {
      debugPrint('Fetching completed test drives for user ID: $userId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.userCompletedTestDrivesEndpoint)}/$userId/completed');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('User completed test drives response status: ${response.statusCode}');
      debugPrint('User completed test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Completed test drives fetched successfully';
          
          debugPrint('Successfully fetched ${testDrives.length} completed test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch completed test drives';
          return ApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        debugPrint('No completed test drives found for user $userId (404)');
        return ApiResponse.success([], message: 'No completed test drives found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch completed test drives');
      }
    } on SocketException {
      debugPrint('User completed test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User completed test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User completed test drives unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> sendForgotPasswordOtp(String emailOrMobile) async {
    try {
      debugPrint('Sending forgot password OTP to: $emailOrMobile');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.forgotPasswordOtpEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email_or_mobile': emailOrMobile,
        }),
      );

      debugPrint('Send OTP response status: ${response.statusCode}');
      debugPrint('Send OTP response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = responseData['message'] as String? ?? 'OTP sent successfully';
        debugPrint('Successfully sent OTP to $emailOrMobile');
        return ApiResponse.success(message, message: message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to send OTP');
      }
    } on SocketException {
      debugPrint('Send OTP network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Send OTP format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Send OTP unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> verifyForgotPasswordOtp(String emailOrMobile, String otp) async {
    try {
      debugPrint('Verifying forgot password OTP for: $emailOrMobile');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.verifyForgotPasswordOtpEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email_or_mobile': emailOrMobile,
          'otp': otp,
        }),
      );

      debugPrint('Verify OTP response status: ${response.statusCode}');
      debugPrint('Verify OTP response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = responseData['message'] as String? ?? 'OTP verified successfully';
        debugPrint('Successfully verified OTP for $emailOrMobile');
        return ApiResponse.success(message, message: message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to verify OTP');
      }
    } on SocketException {
      debugPrint('Verify OTP network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Verify OTP format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Verify OTP unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> resetPassword(String emailOrMobile, String otp, String newPassword) async {
    try {
      debugPrint('Resetting password for: $emailOrMobile');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.resetPasswordEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email_or_mobile': emailOrMobile,
          'otp': otp,
          'new_password': newPassword,
        }),
      );

      debugPrint('Reset password response status: ${response.statusCode}');
      debugPrint('Reset password response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = responseData['message'] as String? ?? 'Password reset successfully';
        debugPrint('Successfully reset password for $emailOrMobile');
        return ApiResponse.success(message, message: message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to reset password');
      }
    } on SocketException {
      debugPrint('Reset password network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Reset password format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Reset password unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> cancelTestDrive(int testDriveId, String cancelDescription) async {
    try {
      debugPrint('Canceling test drive ID: $testDriveId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/app-users/textdrives/status-update/$testDriveId?status=canceled&cancel_description=${Uri.encodeComponent(cancelDescription)}');
      final response = await http.patch(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Cancel test drive response status: ${response.statusCode}');
      debugPrint('Cancel test drive response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final message = responseData['message'] as String? ?? 'Test drive canceled successfully';
        debugPrint('Successfully canceled test drive ID: $testDriveId');
        return ApiResponse.success(message, message: message);
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to cancel test drive');
      }
    } on SocketException {
      debugPrint('Cancel test drive network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Cancel test drive format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Cancel test drive unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<review.ReviewResponse>> submitReview(review.ReviewRequest request) async {
    try {
      debugPrint('Submitting review for test drive ID: ${request.testDriveId}');
      debugPrint('Review data: ${request.toQueryParameters()}');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.reviewEndpoint))
          .replace(queryParameters: request.toQueryParameters());
      
      debugPrint('Submit review URL: $uri');
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Submit review response status: ${response.statusCode}');
      debugPrint('Submit review response data: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final reviewData = responseData['data'] as Map<String, dynamic>;
          final reviewResponse = review.ReviewResponse.fromJson(reviewData);
          final message = responseData['message'] as String? ?? 'Review submitted successfully';
          
          debugPrint('Successfully submitted review with ID: ${reviewResponse.id}');
          return ApiResponse.success(reviewResponse, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to submit review';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to submit review');
      }
    } on SocketException {
      debugPrint('Submit review network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Submit review format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Submit review unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  String? _extractErrorMessage(String responseBody) {
    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      return data['message'] ?? data['error'] ?? data['detail'];
    } catch (e) {
      return null;
    }
  }

  // Retry mechanism for failed requests
  Future<T> _retryRequest<T>(Future<T> Function() request, {int retryCount = 0}) async {
    try {
      return await request();
    } catch (e) {
      if (retryCount < ApiConfig.maxRetries) {
        await Future.delayed(ApiConfig.retryDelay * (retryCount + 1));
        return _retryRequest(request, retryCount: retryCount + 1);
      }
      rethrow;
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}

// Extension for debug print
void debugPrint(String message) {
  // In production, you might want to use a proper logging library
  print('[API] $message');
} 