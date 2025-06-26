# Employee API Integration Documentation

## Overview
This document describes the complete API integration for the employee/driver login functionality in the Varenium app.

## API Endpoint
- **URL**: `https://varenyam.acttconnect.com/api/driver/login`
- **Method**: POST
- **Headers**: 
  ```
  Content-Type: application/json
  Accept: application/json
  ```
- **Request Body**: 
  ```json
  {
    "email": "actt@gmail.com",
    "password": "12345678"
  }
  ```
  OR
  ```json
  {
    "employee_id": "3",
    "password": "12345678"
  }
  ```

## API Response Format
```json
{
    "message": "Login successful.",
    "token": "9|zjibbQ4kneHEImm4JU7otWGU0VORSzqoDDAVYQQs79dc5790",
    "user": {
        "id": 3,
        "name": "sdasdd",
        "email": "actt@gmail.com",
        "email_verified_at": null,
        "status": "active",
        "showroom_id": 2,
        "mobile_no": "8989898989",
        "avatar": "assets/profile/1750224248_68524d784eec6.png",
        "avatar_url": "https://varenyam.acttconnect.com/assets/profile/1750224248_68524d784eec6.png",
        "documents": [
            {
                "id": 3,
                "user_id": 3,
                "document_name": "aadhar",
                "file_path": "assets/userdocuments/1750154029_68513b2d596c9.pdf",
                "created_at": "2025-06-17T09:53:49.000000Z",
                "updated_at": "2025-06-17T09:53:49.000000Z",
                "file_url": "https://varenyam.acttconnect.com/assets/userdocuments/1750154029_68513b2d596c9.pdf"
            }
        ]
    }
}
```

## Implementation Details

### 1. Employee Model (`lib/models/employee_model.dart`)
The employee model handles the data structure for:
- **Employee**: Main employee data including personal info, status, and documents
- **EmployeeDocument**: Document information for the employee
- **EmployeeLoginResponse**: Complete login response with token and user data
- **EmployeeLoginRequest**: Login request parameters
- **EmployeeApiResponse**: Generic API response wrapper

### 2. Employee API Service (`lib/services/employee_api_service.dart`)
Handles all employee-related API calls:
- **login(email, password)**: Login with email using POST request
- **loginWithEmployeeId(employeeId, password)**: Login with employee ID using POST request
- **Error handling**: Network errors, timeouts, and parsing errors
- **Response parsing**: Converts JSON to Dart objects

### 3. Employee Storage Service (`lib/services/employee_storage_service.dart`)
Manages local storage for employee data:
- **saveEmployeeData()**: Saves login response to SharedPreferences
- **getEmployeeData()**: Retrieves stored employee data
- **getEmployeeToken()**: Gets the authentication token
- **isEmployeeLoggedIn()**: Checks login status
- **clearEmployeeData()**: Clears data on logout
- **updateEmployeeData()**: Updates employee information

### 4. Updated Employee Login Screen (`lib/screens/employee/employee_login_screen.dart`)
Enhanced with real API integration:
- **API Integration**: Calls the actual login API using POST method
- **Flexible Input**: Accepts both employee ID and email
- **Data Persistence**: Saves login response to local storage
- **Error Handling**: Displays appropriate error messages
- **Loading States**: Shows loading indicator during API calls

### 5. Updated Employee Home Screen (`lib/screens/employee/employee_home_screen.dart`)
Enhanced to display employee information:
- **Employee Data Display**: Shows employee name and details
- **Logout Functionality**: Proper logout with data clearing
- **Navigation**: Handles logout navigation

## Usage Examples

### Login with Email
```dart
final response = await EmployeeApiService().login('actt@gmail.com', '12345678');
if (response.success && response.data != null) {
  await EmployeeStorageService.saveEmployeeData(response.data!);
  // Navigate to home screen
}
```

### Login with Employee ID
```dart
final response = await EmployeeApiService().loginWithEmployeeId('3', '12345678');
if (response.success && response.data != null) {
  await EmployeeStorageService.saveEmployeeData(response.data!);
  // Navigate to home screen
}
```

### Check Login Status
```dart
bool isLoggedIn = await EmployeeStorageService.isEmployeeLoggedIn();
if (isLoggedIn) {
  Employee? employee = await EmployeeStorageService.getEmployeeData();
  String? token = await EmployeeStorageService.getEmployeeToken();
}
```

### Logout
```dart
await EmployeeStorageService.clearEmployeeData();
// Navigate to login screen
```

## Error Handling

The implementation includes comprehensive error handling for:
- **Network Errors**: No internet connection
- **Timeout Errors**: Request timeout (30 seconds)
- **Parsing Errors**: Invalid JSON response
- **API Errors**: Server-side errors with proper error messages
- **Validation Errors**: Form validation errors

## Security Features

1. **Token Storage**: Authentication tokens are stored securely
2. **Data Validation**: Input validation before API calls
3. **Error Sanitization**: Error messages are sanitized for security
4. **Session Management**: Proper session handling with logout functionality
5. **POST Method**: Uses POST for secure credential transmission

## Testing

A test file (`test_employee_api.dart`) is provided to verify the API integration:
```dart
// Test email login
await EmployeeApiTest.testEmployeeLogin();

// Test employee ID login
await EmployeeApiTest.testEmployeeLoginWithId();
```

## Configuration

The API configuration is managed in `lib/services/api_config.dart`:
- **Base URL**: `https://varenyam.acttconnect.com`
- **Employee Login Endpoint**: `/api/driver/login`
- **Method**: POST
- **Headers**: Standard JSON headers
- **Timeout**: 30 seconds

## Dependencies

Required dependencies in `pubspec.yaml`:
- `http: ^1.1.0` - For API calls
- `shared_preferences: ^2.2.2` - For local storage

## Notes

1. The API supports both email and employee ID login using POST method
2. All employee data is automatically saved to local storage upon successful login
3. The token is stored separately for authentication purposes
4. Logout clears all stored employee data
5. The implementation includes proper loading states and error handling
6. The UI is responsive and works on both mobile and desktop layouts
7. Uses POST method for secure credential transmission

## Error Handling

The implementation includes comprehensive error handling for:
- **Network Errors**: No internet connection
- **Timeout Errors**: Request timeout (30 seconds)
- **Parsing Errors**: Invalid JSON response
- **API Errors**: Server-side errors with proper error messages
- **Validation Errors**: Form validation errors

## Security Features

1. **Token Storage**: Authentication tokens are stored securely
2. **Data Validation**: Input validation before API calls
3. **Error Sanitization**: Error messages are sanitized for security
4. **Session Management**: Proper session handling with logout functionality
5. **POST Method**: Uses POST for secure credential transmission

## Testing

A test file (`test_employee_api.dart`) is provided to verify the API integration:
```dart
// Test email login
await EmployeeApiTest.testEmployeeLogin();

// Test employee ID login
await EmployeeApiTest.testEmployeeLoginWithId();
```

## Configuration

The API configuration is managed in `lib/services/api_config.dart`:
- **Base URL**: `https://varenyam.acttconnect.com`
- **Employee Login Endpoint**: `/api/driver/login`
- **Method**: POST
- **Headers**: Standard JSON headers
- **Timeout**: 30 seconds

## Dependencies

Required dependencies in `pubspec.yaml`:
- `http: ^1.1.0` - For API calls
- `shared_preferences: ^2.2.2` - For local storage

## Notes

1. The API supports both email and employee ID login using POST method
2. All employee data is automatically saved to local storage upon successful login
3. The token is stored separately for authentication purposes
4. Logout clears all stored employee data
5. The implementation includes proper loading states and error handling
6. The UI is responsive and works on both mobile and desktop layouts
7. Uses POST method for secure credential transmission 