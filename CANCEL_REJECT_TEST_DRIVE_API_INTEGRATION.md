# Cancel/Reject Test Drive API Integration

## Overview
This document describes the complete API integration for canceling/rejecting test drives in the Varenium app. The cancel functionality allows employees to reject pending test drive requests with a reason.

## API Endpoint

### Cancel/Reject Test Drive
- **URL**: `https://varenyam.acttconnect.com/api/employee/textdrives/status-update`
- **Method**: POST
- **Headers**: 
  ```
  Content-Type: application/json
  Accept: application/json
  ```

## API Request Parameters

### Query Parameters
- `employee_id` (required): The ID of the employee rejecting the test drive
- `status` (required): Must be "rejected" to reject the test drive
- `testdrive_id` (required): The ID of the test drive to reject
- `reject_description` (required): The reason for rejecting the test drive

## API Response Format

### Success Response
```json
{
    "success": true,
    "message": "Test drive status updated to rejected."
}
```

### Error Response
```json
{
    "success": false,
    "message": "Error message here"
}
```

## Implementation Details

### 1. API Service (`lib/services/api_service.dart`)
Updated the `cancelTestDrive` method:
```dart
Future<ApiResponse<String>> cancelTestDrive(int testDriveId, String cancelDescription, int employeeId) async
```

### 2. Pending Test Drives Screen (`lib/screens/user/pending_test_drives_screen.dart`)
Updated to:
- Use the new API endpoint with employee ID
- Load user data from secure storage
- Handle API responses properly
- Show proper success/error messages
- Refresh data after successful cancellation

## Usage Examples

### Cancel/Reject Test Drive
```dart
final response = await ApiService().cancelTestDrive(
  testDriveId: 57,
  cancelDescription: 'I\'m no longer available at the selected time',
  employeeId: 2,
);

if (response.success) {
  print('Test drive rejected: ${response.message}');
} else {
  print('Error: ${response.message}');
}
```

## UI Features

### Cancel Dialog
- Shows confirmation dialog before canceling
- Optional reason field for cancellation
- Validation for required fields
- Loading state during API call

### Error Handling
- Network error handling
- API error handling
- User data validation
- Graceful fallbacks for missing data

## Data Flow

1. **User Action**: User clicks "Cancel Test Drive" button
2. **Confirmation Dialog**: Shows dialog with reason field
3. **User Input**: User enters reason and confirms
4. **API Call**: Calls cancel API with test drive ID, reason, and employee ID
5. **Response Handling**: Shows success/error message based on API response
6. **Data Refresh**: Refreshes the pending test drives list

## Key Changes from Previous Implementation

### Old Implementation
- **Endpoint**: `/api/app-users/textdrives/status-update/{id}`
- **Method**: PATCH
- **Status**: `canceled`
- **Parameter**: `cancel_description`

### New Implementation
- **Endpoint**: `/api/employee/textdrives/status-update`
- **Method**: POST
- **Status**: `rejected`
- **Parameters**: `employee_id`, `testdrive_id`, `reject_description`

## Configuration

The API configuration is managed in `lib/services/api_config.dart`:
- **Base URL**: `https://varenyam.acttconnect.com`
- **Cancel Test Drive Endpoint**: `/api/employee/textdrives/status-update`
- **Method**: POST
- **Headers**: Standard JSON headers
- **Timeout**: 30 seconds

## Dependencies

Required dependencies in `pubspec.yaml`:
- `http: ^1.1.0` - For API calls
- `flutter_secure_storage: ^9.0.0` - For secure storage
- `shared_preferences: ^2.2.2` - For local storage

## Security Features

1. **Secure Storage**: User data is stored securely using flutter_secure_storage
2. **Parameter Validation**: All parameters are validated before API calls
3. **Error Sanitization**: Error messages are sanitized for security
4. **Required Fields**: Proper validation for required fields

## Key Features

### Cancel/Reject Functionality
- **Employee Tracking**: Records which employee rejected the test drive
- **Reason Tracking**: Records the reason for rejection
- **Status Update**: Changes test drive status from "pending" to "rejected"
- **Real-time Updates**: Immediately reflects changes in the UI

## Error Handling

The implementation includes comprehensive error handling for:
- **Network Errors**: No internet connection
- **Timeout Errors**: Request timeout (30 seconds)
- **Parsing Errors**: Invalid JSON response
- **API Errors**: Server-side errors with proper error messages
- **Validation Errors**: Form validation errors
- **Authentication Errors**: Missing user data

## Notes

1. The API uses POST method for status updates
2. All required parameters must be provided
3. The employee ID must be valid
4. The test drive must be in "pending" status
5. Success response includes a confirmation message
6. Error responses include descriptive error messages
7. The status is changed to "rejected" instead of "canceled"

## API Examples

### Complete Cancel/Reject Test Drive Request
```
POST https://varenyam.acttconnect.com/api/employee/textdrives/status-update?employee_id=2&status=rejected&testdrive_id=57&reject_description=I'm%20no%20longer%20available%20at%20the%20selected%20time
```

## Troubleshooting

### Common Issues

1. **Network Error**: Check internet connection
2. **Timeout Error**: Server may be slow, retry the request
3. **Validation Error**: Ensure all required fields are filled
4. **Authentication Error**: User may need to login again
5. **API Error**: Check server logs for detailed error information

### Debug Information

The implementation includes comprehensive debug logging:
- API request URLs
- Request parameters
- Response status codes
- Response data
- Error messages

Enable debug mode to see detailed logs during development.

## Future Enhancements

1. **Real-time Updates**: Implement WebSocket for real-time status updates
2. **Push Notifications**: Add notifications for rejected test drives
3. **Offline Support**: Cache pending test drives for offline viewing
4. **Batch Operations**: Allow rejecting multiple test drives at once
5. **Advanced Filtering**: Add filters for pending test drives
6. **Reason Templates**: Predefined rejection reasons for quick selection 