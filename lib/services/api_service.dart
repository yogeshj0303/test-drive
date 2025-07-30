import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/showroom_model.dart';
import '../models/car_model.dart';
import '../models/test_drive_model.dart';
import '../models/expense_model.dart';
import '../models/activity_log_model.dart';
import 'api_config.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final StorageService _storageService = StorageService();

  // Get authenticated headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storageService.getToken();
    return ApiConfig.getAuthHeaders(token);
  }



  Future<ApiResponse<LoginResponse>> login(String emailOrMobile, String password) async {
    try {
      debugPrint('Attempting login for: $emailOrMobile');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.loginEndpoint)}?email=$emailOrMobile&password=$password');
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
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

  Future<ApiResponse<Showroom>> getShowroomById(int showroomId) async {
    try {
      debugPrint('Fetching showroom details for ID: $showroomId');
      
      // Use query parameter instead of path parameter
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.showroomByIdEndpoint)}?showroom_id=$showroomId');
      debugPrint('Showroom details URL: $uri');
      
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Showroom details response status: ${response.statusCode}');
      debugPrint('Showroom details response data: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        
        Showroom showroom;
        
        // Handle both List and Map responses
        if (responseData is List) {
          // API returned a list of showrooms, take the first one
          if (responseData.isNotEmpty) {
            showroom = Showroom.fromJson(responseData.first as Map<String, dynamic>);
          } else {
            debugPrint('No showrooms found for ID: $showroomId');
            return ApiResponse.error('Showroom not found');
          }
        } else if (responseData is Map<String, dynamic>) {
          // API returned a single showroom object
          showroom = Showroom.fromJson(responseData);
        } else {
          debugPrint('Unexpected response format: $responseData');
          return ApiResponse.error('Invalid response format from server');
        }
        
        debugPrint('Successfully fetched showroom details for ID $showroomId');
        return ApiResponse.success(showroom, message: 'Showroom details fetched successfully');
      } else if (response.statusCode == 404) {
        debugPrint('Showroom not found for ID: $showroomId');
        return ApiResponse.error('Showroom not found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        debugPrint('Showroom details API error: $errorMessage');
        return ApiResponse.error(errorMessage ?? 'Failed to fetch showroom details');
      }
    } on SocketException {
      debugPrint('Showroom details network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Showroom details format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Showroom details unexpected error: ${e.toString()}');
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

  Future<ApiResponse<List<Car>>> getCarsByLocationType(String locationType) async {
    try {
      debugPrint('Fetching cars by location type: $locationType');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.carsByLocationTypeEndpoint)}?car_location_type=$locationType');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Cars by location type response status: ${response.statusCode}');
      debugPrint('Cars by location type response data: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body) as List<dynamic>;
        final cars = responseData.map((json) => Car.fromJson(json)).toList();
        debugPrint('Successfully fetched ${cars.length} cars for location type $locationType');
        return ApiResponse.success(cars, message: 'Cars fetched successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch cars');
      }
    } on SocketException {
      debugPrint('Cars by location type network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Cars by location type format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Cars by location type unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<User>> getUserProfile(int userId) async {
    try {
      debugPrint('Fetching user profile for user ID: $userId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.userProfileEndpoint)}/$userId');
      final headers = await _getAuthHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      );

      debugPrint('User profile response status: ${response.statusCode}');
      debugPrint('User profile response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Handle nested user structure
        Map<String, dynamic> userData;
        if (responseData.containsKey('user')) {
          userData = responseData['user'] as Map<String, dynamic>;
        } else {
          userData = responseData; // Fallback to direct user data
        }
        
        final user = User.fromJson(userData);
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

  Future<ApiResponse<String>> changePassword(int userId, String newPassword) async {
    try {
      debugPrint('Changing password for user ID: $userId');
      
      // Build query parameters for the new API
      final queryParams = <String, String>{
        'user_id': userId.toString(),
        'new_password': newPassword,
        'confirm_password': newPassword, // Using newPassword as confirm_password
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
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.testDriveStoreEndpoint));
      
      debugPrint('Test drive request URL: $uri');
      
      http.Response response;
      
      // Check if we have images to upload
      if (request.carImages != null && request.carImages!.isNotEmpty) {
        // Use multipart request for image upload
        var request_ = http.MultipartRequest('POST', uri);
        
        // Add text fields
        request_.fields.addAll(request.toQueryParameters());
        
        // Define the expected field names for car images
        final imageFieldNames = [
          'car_front_img',    // Front image
          'right_side_img',   // Right side image
          'back_car_img',     // Rear image
          'left_side_img',    // Left side image
          'upper_view',       // Inside/upper view image
        ];
        
        // Add image files with specific field names
        for (int i = 0; i < request.carImages!.length && i < imageFieldNames.length; i++) {
          final file = request.carImages![i];
          final fieldName = imageFieldNames[i];
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          final multipartFile = http.MultipartFile(
            fieldName, // Use specific field name for each image
            stream,
            length,
            filename: '${fieldName}_${i}.jpg',
          );
          request_.files.add(multipartFile);
        }
        
        // Send multipart request
        final streamedResponse = await request_.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Use regular POST request without images
        response = await http.post(
          uri,
          headers: ApiConfig.defaultHeaders,
          body: jsonEncode(request.toJson()),
        );
      }

      debugPrint('Test drive request response status: ${response.statusCode}');
      debugPrint('Test drive request response data: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          
          if (responseData['success'] == true) {
            // Handle both direct data and nested data structure
            Map<String, dynamic> testDriveData;
            if (responseData.containsKey('data')) {
              testDriveData = responseData['data'] as Map<String, dynamic>;
            } else {
              // If no 'data' field, use the response directly
              testDriveData = responseData;
            }
            
            debugPrint('Parsing test drive data: $testDriveData');
            
            final testDriveResponse = TestDriveResponse.fromJson(testDriveData);
            final message = responseData['message'] as String? ?? 'Test drive request submitted successfully';
            
            debugPrint('Successfully submitted test drive request with ID: ${testDriveResponse.id}');
            return ApiResponse.success(testDriveResponse, message: message);
          } else {
            final errorMessage = responseData['message'] as String? ?? 'Failed to submit test drive request';
            debugPrint('API returned success=false: $errorMessage');
            return ApiResponse.error(errorMessage);
          }
        } catch (e) {
          debugPrint('Error parsing response JSON: $e');
          debugPrint('Response body: ${response.body}');
          return ApiResponse.error('Invalid response format from server');
        }
      } else if (response.statusCode == 500) {
        // Handle the specific backend error
        final errorMessage = _extractErrorMessage(response.body);
        debugPrint('Server error (500): $errorMessage');
        return ApiResponse.error(_getUserFriendlyErrorMessage(errorMessage));
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        debugPrint('API error (${response.statusCode}): $errorMessage');
        return ApiResponse.error(_getUserFriendlyErrorMessage(errorMessage));
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
      
      // Use GET instead of POST, pass userId as query param
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/employee/all/testdrives?users_id=$userId');
      final headers = await _getAuthHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      );

      debugPrint('User test drives response status:  [32m [1m${response.statusCode} [0m');
      debugPrint('User test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Test drives fetched successfully';
          
          debugPrint('Successfully fetched  [32m${testDrives.length} [0m test drives for user $userId');
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
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.userPendingTestDrivesEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'users_id': userId,
        }),
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

  Future<ApiResponse<List<TestDriveListResponse>>> getUserCancelledTestDrives(int userId) async {
    try {
      debugPrint('Fetching cancelled test drives for user ID: $userId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.userCancelledTestDrivesEndpoint)}/$userId/cancelled');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('User cancelled test drives response status: ${response.statusCode}');
      debugPrint('User cancelled test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
                  final message = responseData['message'] as String? ?? 'Cancelled test drives fetched successfully';
        
        debugPrint('Successfully fetched ${testDrives.length} cancelled test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch cancelled test drives';
          return ApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        debugPrint('No cancelled test drives found for user $userId (404)');
        return ApiResponse.success([], message: 'No cancelled test drives found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch cancelled test drives');
      }
    } on SocketException {
      debugPrint('User cancelled test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User cancelled test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User cancelled test drives unexpected error: ${e.toString()}');
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

  Future<ApiResponse<List<TestDriveListResponse>>> getUserRescheduledTestDrives(int userId) async {
    try {
      debugPrint('Fetching rescheduled test drives for user ID: $userId');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.userRescheduledTestDrivesEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'users_id': userId,
          'status': 'rescheduled',
        }),
      );

      debugPrint('User rescheduled test drives response status: ${response.statusCode}');
      debugPrint('User rescheduled test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Rescheduled test drives fetched successfully';
          
          debugPrint('Successfully fetched ${testDrives.length} rescheduled test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch rescheduled test drives';
          return ApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        debugPrint('No rescheduled test drives found for user $userId (404)');
        return ApiResponse.success([], message: 'No rescheduled test drives found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch rescheduled test drives');
      }
    } on SocketException {
      debugPrint('User rescheduled test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User rescheduled test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User rescheduled test drives unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<TestDriveListResponse>>> getUserApprovedTestDrives(int userId) async {
    try {
      debugPrint('Fetching approved test drives for user ID: $userId');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.userRescheduledTestDrivesEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'users_id': userId,
          'status': 'approved',
        }),
      );

      debugPrint('User approved test drives response status: ${response.statusCode}');
      debugPrint('User approved test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Approved test drives fetched successfully';
          
          debugPrint('Successfully fetched ${testDrives.length} approved test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch approved test drives';
          return ApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        debugPrint('No approved test drives found for user $userId (404)');
        return ApiResponse.success([], message: 'No approved test drives found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch approved test drives');
      }
    } on SocketException {
      debugPrint('User approved test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User approved test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User approved test drives unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<TestDriveListResponse>>> getUserRejectedTestDrives(int userId) async {
    try {
      debugPrint('Fetching rejected test drives for user ID: $userId');
      
      final uri = Uri.parse(ApiConfig.getFullUrl(ApiConfig.userRescheduledTestDrivesEndpoint));
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'users_id': userId,
          'status': 'rejected',
        }),
      );

      debugPrint('User rejected test drives response status: ${response.statusCode}');
      debugPrint('User rejected test drives response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> data = responseData['data'] as List<dynamic>;
          final testDrives = data.map((json) => TestDriveListResponse.fromJson(json)).toList();
          final message = responseData['message'] as String? ?? 'Rejected test drives fetched successfully';
          
          debugPrint('Successfully fetched ${testDrives.length} rejected test drives for user $userId');
          return ApiResponse.success(testDrives, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch rejected test drives';
          return ApiResponse.error(errorMessage);
        }
      } else if (response.statusCode == 404) {
        debugPrint('No rejected test drives found for user $userId (404)');
        return ApiResponse.success([], message: 'No rejected test drives found');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch rejected test drives');
      }
    } on SocketException {
      debugPrint('User rejected test drives network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('User rejected test drives format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('User rejected test drives unexpected error: ${e.toString()}');
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

  Future<ApiResponse<List<Map<String, dynamic>>>> getShowroomDrivers(int showroomId) async {
    try {
      debugPrint('Fetching drivers for showroom ID: $showroomId');
      
      final uri = Uri.parse('${ApiConfig.getFullUrl(ApiConfig.driverListEndpoint)}?showroom_id=$showroomId');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Drivers response status: ${response.statusCode}');
      debugPrint('Drivers response data: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body) as List<dynamic>;
        final drivers = responseData.map((json) => json as Map<String, dynamic>).toList();
        debugPrint('Successfully fetched ${drivers.length} drivers for showroom $showroomId');
        return ApiResponse.success(drivers, message: 'Drivers fetched successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch drivers');
      }
    } on SocketException {
      debugPrint('Drivers network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Drivers format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Drivers unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> cancelTestDrive(int testDriveId, String cancelDescription, int employeeId) async {
    try {
      debugPrint('Canceling test drive ID: $testDriveId with employee ID: $employeeId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/employee/textdrives/status-update?employee_id=$employeeId&status=rejected&testdrive_id=$testDriveId&reject_description=${Uri.encodeComponent(cancelDescription)}');
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Cancel test drive response status: ${response.statusCode}');
      debugPrint('Cancel test drive response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Test drive status updated to rejected.';
          debugPrint('Successfully cancelled test drive ID: $testDriveId');
          return ApiResponse.success(message, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to cancel test drive';
          return ApiResponse.error(errorMessage);
        }
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

  Future<ApiResponse<String>> approveTestDrive(int testDriveId, int driverId, int employeeId) async {
    try {
      debugPrint('Approving test drive ID: $testDriveId with driver ID: $driverId and employee ID: $employeeId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/textdrives/driver/status-update?driver_id=$driverId&status=approved&testdrive_id=$testDriveId&employee_id=$employeeId');
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Approve test drive response status: ${response.statusCode}');
      debugPrint('Approve test drive response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Test drive approved successfully';
          debugPrint('Successfully approved test drive ID: $testDriveId');
          return ApiResponse.success(message, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to approve test drive';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to approve test drive');
      }
    } on SocketException {
      debugPrint('Approve test drive network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Approve test drive format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Approve test drive unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> rescheduleTestDrive(int testDriveId, String newDate, int employeeId) async {
    try {
      debugPrint('Rescheduling test drive ID: $testDriveId with new date: $newDate, employee ID: $employeeId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/employee/textdrives/status-update?employee_id=$employeeId&status=rescheduled&testdrive_id=$testDriveId&next_date=$newDate');
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Reschedule test drive response status: ${response.statusCode}');
      debugPrint('Reschedule test drive response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Test drive status updated to rescheduled.';
          debugPrint('Successfully rescheduled test drive ID: $testDriveId');
          return ApiResponse.success(message, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to reschedule test drive';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to reschedule test drive');
      }
    } on SocketException {
      debugPrint('Reschedule test drive network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Reschedule test drive format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Reschedule test drive unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> updateTestDriveStatus({
    required String driverId,
    required String status,
    required int testDriveId,
    required int employeeId,
  }) async {
    try {
      debugPrint('Updating test drive status - ID: $testDriveId, Driver: $driverId, Status: $status, Employee: $employeeId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/employee/textdrives/status-update?driver_id=$driverId&status=$status&testdrive_id=$testDriveId&employee_id=$employeeId');
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Update test drive status response status: ${response.statusCode}');
      debugPrint('Update test drive status response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Test drive status updated successfully.';
          debugPrint('Successfully updated test drive status ID: $testDriveId to $status');
          return ApiResponse.success(message, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to update test drive status';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to update test drive status');
      }
    } on SocketException {
      debugPrint('Update test drive status network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Update test drive status format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Update test drive status unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> completeTestDrive({
    required int testDriveId,
    required int employeeId,
    required int closingKm,
    required Map<String, String> returnImages,
  }) async {
    try {
      debugPrint('Completing test drive - ID: $testDriveId, Employee: $employeeId, Closing KM: $closingKm');
      
      // Build query parameters
      final queryParams = <String, String>{
        'employee_id': employeeId.toString(),
        'status': 'completed',
        'testdrive_id': testDriveId.toString(),
        'closing_km': closingKm.toString(),
      };
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/employee/textdrives/status-update')
          .replace(queryParameters: queryParams);
      
      // Prepare request body for required return images
      Map<String, dynamic> requestBody = {};
      
      // Add return images to request body with specific field names
      // The API expects return_* field names for images
      requestBody.addAll(returnImages);
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode(requestBody),
      );

      debugPrint('Complete test drive response status: ${response.statusCode}');
      debugPrint('Complete test drive response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Test drive completed successfully.';
          debugPrint('Successfully completed test drive ID: $testDriveId');
          return ApiResponse.success(message, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to complete test drive';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to complete test drive');
      }
    } on SocketException {
      debugPrint('Complete test drive network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Complete test drive format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Complete test drive unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }



  Future<ApiResponse<List<ExpenseResponse>>> getExpensesList(int userId, {String? status}) async {
    try {
      debugPrint('Fetching expenses for user ID: $userId, status: $status');
      
      final queryParams = <String, String>{
        'user_id': userId.toString(),
      };
      
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status.toLowerCase();
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/expenses/list')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Expenses list response status: ${response.statusCode}');
      debugPrint('Expenses list response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final List<dynamic> expensesData = responseData['data'] as List<dynamic>;
          final expenses = expensesData.map((json) => ExpenseResponse.fromJson(json as Map<String, dynamic>)).toList();
          
          debugPrint('Successfully fetched ${expenses.length} expenses for user $userId with status: $status');
          return ApiResponse.success(expenses, message: responseData['message'] as String? ?? 'Expenses fetched successfully');
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to fetch expenses';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch expenses');
      }
    } on SocketException {
      debugPrint('Expenses list network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Expenses list format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Expenses list unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> approveExpense(int expenseId, int approverId) async {
    try {
      debugPrint('Approving expense ID: $expenseId by approver ID: $approverId');
      
      // Build query parameters
      final queryParams = <String, String>{
        'expences_id': expenseId.toString(),
        'approved_reject_by': approverId.toString(),
        'status': 'approved',
      };
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/expenses/change-status')
          .replace(queryParameters: queryParams);
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Approve expense response status: ${response.statusCode}');
      debugPrint('Approve expense response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Expense approved successfully';
          debugPrint('Successfully approved expense ID: $expenseId');
          return ApiResponse.success(message, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to approve expense';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to approve expense');
      }
    } on SocketException {
      debugPrint('Approve expense network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Approve expense format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Approve expense unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<String>> rejectExpense(int expenseId, int rejectorId, {String? rejectDescription}) async {
    try {
      debugPrint('Rejecting expense ID: $expenseId by rejector ID: $rejectorId');
      
      // Build query parameters
      final queryParams = <String, String>{
        'expences_id': expenseId.toString(),
        'approved_reject_by': rejectorId.toString(),
        'status': 'rejected',
      };
      
      if (rejectDescription != null && rejectDescription.isNotEmpty) {
        queryParams['reject_description'] = rejectDescription;
      }
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/expenses/change-status')
          .replace(queryParameters: queryParams);
      
      final response = await http.post(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      debugPrint('Reject expense response status: ${response.statusCode}');
      debugPrint('Reject expense response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (responseData['success'] == true) {
          final message = responseData['message'] as String? ?? 'Expense rejected successfully';
          debugPrint('Successfully rejected expense ID: $expenseId');
          return ApiResponse.success(message, message: message);
        } else {
          final errorMessage = responseData['message'] as String? ?? 'Failed to reject expense';
          return ApiResponse.error(errorMessage);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to reject expense');
      }
    } on SocketException {
      debugPrint('Reject expense network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Reject expense format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('Reject expense unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<ActivityLogResponse>> getRecentActivities({
    required int userId,
    String userType = 'users',
  }) async {
    try {
      debugPrint('Fetching recent activities for user ID: $userId, user type: $userType');
      
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/activities?user_id=$userId&user_type=$userType',
      );
      
      debugPrint('Activities API URL: $uri');
      
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 30));

      debugPrint('Activities response status: ${response.statusCode}');
      debugPrint('Activities response data: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final activityLogResponse = ActivityLogResponse.fromJson(responseData);
        
        debugPrint('Parsed ${activityLogResponse.data.length} activities');
        
        if (activityLogResponse.success) {
          return ApiResponse.success(activityLogResponse, message: activityLogResponse.message);
        } else {
          return ApiResponse.error(activityLogResponse.message);
        }
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch recent activities');
      }
    } on SocketException {
      debugPrint('Activities network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('Activities format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } on TimeoutException {
      debugPrint('Activities timeout error: Request timeout');
      return ApiResponse.error('Request timeout. Please try again.');
    } catch (e) {
      debugPrint('Activities unexpected error: ${e.toString()}');
      return ApiResponse.error('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<ApiResponse<List<Showroom>>> getAllShowrooms() async {
    try {
      debugPrint('Fetching all showrooms');
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/front-showrooms');
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );
      debugPrint('All showrooms response status: ${response.statusCode}');
      debugPrint('All showrooms response data: ${response.body}');
      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
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
        debugPrint('Successfully fetched ${showrooms.length} showrooms');
        return ApiResponse.success(showrooms, message: 'Showrooms fetched successfully');
      } else {
        final errorMessage = _extractErrorMessage(response.body);
        return ApiResponse.error(errorMessage ?? 'Failed to fetch showrooms');
      }
    } on SocketException {
      debugPrint('All showrooms network error: No internet connection');
      return ApiResponse.error(ApiConfig.networkErrorMessage);
    } on FormatException {
      debugPrint('All showrooms format error: Invalid response format');
      return ApiResponse.error('Invalid response format from server');
    } catch (e) {
      debugPrint('All showrooms unexpected error: ${e.toString()}');
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

  // Utility method to detect backend issues
  bool _isBackendIssue(String? errorMessage) {
    if (errorMessage == null) return false;
    
    final lowerMessage = errorMessage.toLowerCase();
    return lowerMessage.contains('activity') ||
           lowerMessage.contains('class not found') ||
           lowerMessage.contains('controller not found') ||
           lowerMessage.contains('500') ||
           lowerMessage.contains('internal server error');
  }

  // Get user-friendly error message
  String _getUserFriendlyErrorMessage(String? errorMessage) {
    if (_isBackendIssue(errorMessage)) {
      return 'Server maintenance in progress. Please try again later or contact support if the issue persists.';
    }
    return errorMessage ?? 'An unexpected error occurred. Please try again.';
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