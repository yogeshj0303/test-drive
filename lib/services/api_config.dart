class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://varenyam.acttconnect.com';
  
  // API Endpoints
  static const String loginEndpoint = '/api/driver/login';
  static const String employeeLoginEndpoint = '/api/driver/login';
  static const String employeeProfileEndpoint = '/api/driver/profile'; // Endpoint for fetching employee profile
  static const String changePasswordEndpoint = '/api/change-password-app';
  static const String forgotPasswordOtpEndpoint = '/api/front-user/forgot-password-otp';
  static const String verifyForgotPasswordOtpEndpoint = '/api/front-user/verify-forgot-password-otp';
  static const String resetPasswordEndpoint = '/api/front-user/reset-password';
  static const String showroomByIdEndpoint = '/api/front-showrooms'; // Endpoint for fetching showroom by ID
  static const String carsByShowroomEndpoint = '/api/front-cars/by-showroom';
  static const String carsByLocationTypeEndpoint = '/api/front-cars/by-location_type';
  static const String userProfileEndpoint = '/api/driver/profile'; // Base endpoint for user profile
  static const String updateUserProfileEndpoint = '/api/app-users/update'; // Endpoint for updating user profile
  static const String testDriveStoreEndpoint = '/api/app-users/textdrives-store'; // Endpoint for creating test drive request
  static const String userTestDrivesEndpoint = '/api/app-users/testdrives'; // Endpoint for fetching user test drives
  static const String userPendingTestDrivesEndpoint = '/api/employee/all/testdrives/unassigned'; // Endpoint for fetching user pending test drives
  static const String userCancelledTestDrivesEndpoint = '/api/app-users/testdrives/user'; // Endpoint for fetching user cancelled test drives
  static const String userCompletedTestDrivesEndpoint = '/api/app-users/testdrives/user'; // Endpoint for fetching user completed test drives
  static const String userRescheduledTestDrivesEndpoint = '/api/employee/testdrives_with_status'; // Endpoint for fetching user rescheduled test drives

  static const String expenseEndpoint = '/api/expenses'; // Endpoint for submitting expenses
  static const String testDriveStatusUpdateEndpoint = '/api/textdrives/driver/status-update'; // Endpoint for updating test drive status
  static const String driverTestDrivesByStatusEndpoint = '/api/driver/testdrives/status'; // Endpoint for fetching test drives by status
  static const String driverListEndpoint = '/api/textdrive/driverlist'; // Endpoint for fetching showroom drivers
  
  // API Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get headers with authentication token
  static Map<String, String> getAuthHeaders(String? token) {
    final headers = Map<String, String>.from(defaultHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
  
  // Timeout settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your internet connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String timeoutErrorMessage = 'Request timeout. Please try again.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  
  // Success messages
  static const String loginSuccessMessage = 'Login successful!';
  
  // Validation messages
  static const String emailAlreadyExistsMessage = 'Email already exists. Please use a different email.';
  static const String invalidCredentialsMessage = 'Invalid email or password.';
  
  // Get full URL for endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
} 