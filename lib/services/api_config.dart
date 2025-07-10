class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://varenyam.acttconnect.com';
  
  // API Endpoints
  static const String loginEndpoint = '/api/driver/login';
  static const String employeeLoginEndpoint = '/api/driver/login';
  static const String employeeProfileEndpoint = '/api/driver/profile'; // Endpoint for fetching employee profile
  static const String changePasswordEndpoint = '/api/front-user/change-password';
  static const String forgotPasswordOtpEndpoint = '/api/front-user/forgot-password-otp';
  static const String verifyForgotPasswordOtpEndpoint = '/api/front-user/verify-forgot-password-otp';
  static const String resetPasswordEndpoint = '/api/front-user/reset-password';
  static const String showroomsEndpoint = '/api/front-showrooms';
  static const String carsByShowroomEndpoint = '/api/front-cars/by-showroom';
  static const String userProfileEndpoint = '/api/app-users'; // Base endpoint for user profile
  static const String updateUserProfileEndpoint = '/api/app-users/update'; // Endpoint for updating user profile
  static const String testDriveStoreEndpoint = '/api/app-users/textdrives-store'; // Endpoint for creating test drive request
  static const String userTestDrivesEndpoint = '/api/app-users/textdrives'; // Endpoint for fetching user test drives
  static const String userPendingTestDrivesEndpoint = '/api/employee/all/textdrives/unassigned'; // Endpoint for fetching user pending test drives
  static const String userCanceledTestDrivesEndpoint = '/api/app-users/textdrives/user'; // Endpoint for fetching user canceled test drives
  static const String userCompletedTestDrivesEndpoint = '/api/app-users/textdrives/user'; // Endpoint for fetching user completed test drives
  static const String userRescheduledTestDrivesEndpoint = '/api/employee/textdrives_with_status'; // Endpoint for fetching user rescheduled test drives
  static const String reviewEndpoint = '/api/app-users/reviews'; // Endpoint for submitting reviews
  static const String expenseEndpoint = '/api/expenses'; // Endpoint for submitting expenses
  static const String testDriveStatusUpdateEndpoint = '/api/textdrives/driver/status-update'; // Endpoint for updating test drive status
  static const String driverListEndpoint = '/api/textdrive/driverlist'; // Endpoint for fetching showroom drivers
  
  // API Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
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