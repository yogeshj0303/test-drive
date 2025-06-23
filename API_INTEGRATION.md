# API Integration Documentation

## Overview
This document describes the API integration implemented for the Varenyam app, covering both user signup and login functionality.

## API Endpoints

### Base URL
```
https://varenyam.acttconnect.com
```

### Endpoints

#### 1. User Signup
- **URL**: `/api/front-user/signup`
- **Method**: `POST`
- **Content-Type**: `application/json`

**Request Body:**
```json
{
  "name": "User Name",
  "email": "user@example.com",
  "password": "password123",
  "mobile": "1234567890",
  "city": "City Name",
  "state": "State Name",
  "district": "District Name",
  "pincode": "123456"
}
```

**Response:**
```json
{
  "id": 16,
  "name": "User Name",
  "email": "user@example.com",
  "mobile": "1234567890",
  "city": "City Name",
  "state": "State Name",
  "district": "District Name",
  "pincode": "123456",
  "created_at": "2025-06-21T05:54:55.000000Z",
  "updated_at": "2025-06-21T05:54:55.000000Z"
}
```

#### 2. User Login
- **URL**: `/api/front-user/login`
- **Method**: `POST`
- **Content-Type**: `application/json`

**Request Body:**
```json
{
  "email_or_mobile": "user@example.com",
  "password": "password123"
}
```

**Example Request:**
```
POST /api/front-user/login
Content-Type: application/json

{
  "email_or_mobile": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "user_id": 15,
  "user": {
    "id": 15,
    "name": "User Name",
    "email": "user@example.com",
    "mobile": "1234567890",
    "created_at": "2025-06-20T07:26:03.000000Z",
    "updated_at": "2025-06-21T05:41:39.000000Z",
    "city": "City Name",
    "state": "State Name",
    "district": "District Name",
    "pincode": "123456"
  }
}
```

## Auto-Login System

The app includes an automatic login system that checks for existing user sessions on app startup.

### How It Works

1. **Splash Screen Check**: When the app starts, the splash screen checks for valid authentication data
2. **Session Validation**: Validates login state and user data (no tokens required)
3. **Automatic Navigation**: 
   - If valid session exists → Navigate to User Home Screen
   - If no valid session → Navigate to Auth Screen

### Session Storage

The app securely stores:
- User login state (`is_logged_in`)
- User profile data (`user_data`)

**Note**: This API doesn't use authentication tokens. Authentication is handled through session-based login state.

### Logout Functionality

Users can logout from multiple locations:

1. **Profile Screen**: Dedicated logout button at the bottom
2. **Home Screen**: Menu button (three dots) in the app bar

**Logout Process:**
- Shows confirmation dialog
- Displays loading indicator during logout
- Clears all stored authentication data
- Shows success confirmation message
- Navigates back to auth screen

**Features:**
- Professional confirmation dialog
- Loading states during logout process
- Success/error feedback with SnackBar
- Complete session cleanup
- Automatic navigation to auth screen

### Security Features

- Uses `flutter_secure_storage` for encrypted data storage
- Validates login state and user data before auto-login
- Handles errors gracefully with fallback to auth screen

## Implementation Details

### Architecture
- **Models**: Data classes for API requests and responses
- **Services**: API service layer with error handling
- **Storage**: Secure storage for user data and authentication state

### Key Features
- ✅ Professional error handling with user-friendly messages
- ✅ Secure storage using `flutter_secure_storage`
- ✅ Form validation for all fields
- ✅ Loading states and user feedback
- ✅ Automatic navigation after successful authentication
- ✅ Debug logging for troubleshooting
- ✅ Retry mechanism for failed requests

### Error Handling
The API service handles various HTTP status codes:
- `400`: Bad request
- `401`: Invalid credentials
- `403`: Access forbidden
- `404`: Resource not found
- `409`: Email already exists
- `422`: Validation error
- `500`: Server error

### Security
- User data is stored securely using `flutter_secure_storage`
- Passwords are not stored locally
- Authentication state is managed securely
- API calls include proper headers and timeout handling

## Testing

### Test Credentials
You can use the following test credentials:
- **Email**: `yash@acttconnect.com`
- **Password**: `111111`

### Debug Information
The API service includes comprehensive logging. Check the console output for:
- Request details
- Response status and data
- Error messages
- Success confirmations

## Usage

### Signup Flow
1. User fills out the signup form
2. Form validation is performed
3. API request is sent to `/api/front-user/signup`
4. On success, user data is stored securely
5. User is navigated to home screen

### Login Flow
1. User enters email/mobile and password
2. Form validation is performed
3. API request is sent to `/api/front-user/login`
4. On success, user data is stored securely
5. User is navigated to home screen

## Dependencies
- `http: ^1.1.0` - HTTP client for API requests
- `flutter_secure_storage: ^9.0.0` - Secure storage

## Configuration
Update the base URL in `lib/services/api_config.dart` if needed:
```dart
static const String baseUrl = 'https://varenyam.acttconnect.com';
```

## Implementation Notes
- Uses the `http` package for all API requests
- Handles network errors, format errors, and unexpected errors
- Includes comprehensive logging for debugging
- Supports retry mechanism for failed requests 