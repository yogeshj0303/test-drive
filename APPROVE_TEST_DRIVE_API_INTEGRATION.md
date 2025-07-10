# Approve Test Drive API Integration

## Overview
This document describes the complete API integration for approving test drives in the Varenium app. The approve functionality allows employees to approve pending test drive requests and assign drivers to them.

## API Endpoint

### Approve Test Drive
- **URL**: `https://varenyam.acttconnect.com/api/textdrives/driver/status-update`
- **Method**: POST
- **Headers**: 
  ```
  Content-Type: application/json
  Accept: application/json
  ```

## API Request Parameters

### Query Parameters
- `driver_id` (required): The ID of the driver to assign to the test drive
- `status` (required): Must be "approved" to approve the test drive
- `testdrive_id` (required): The ID of the test drive to approve
- `employee_id` (required): The ID of the employee approving the test drive

## API Response Format

### Success Response
```json
{
    "success": true,
    "message": "Test drive status updated to approved."
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
Added the `approveTestDrive` method:
```dart
Future<ApiResponse<String>> approveTestDrive(int testDriveId, int driverId, int employeeId) async
```

### 2. Pending Test Drives Screen (`lib/screens/user/pending_test_drives_screen.dart`)
Updated to:
- Use real API calls instead of mock data
- Load user data from secure storage
- Handle API responses properly
- Show proper success/error messages
- Refresh data after successful approval

### 3. Reschedule Test Drive API
Added the `rescheduleTestDrive` method:
```dart
Future<ApiResponse<String>> rescheduleTestDrive(int testDriveId, String newDate, String newTime, String reason, int employeeId) async
```

## Usage Examples

### Approve Test Drive
```dart
final response = await ApiService().approveTestDrive(
  testDriveId: 53,
  driverId: 3,
  employeeId: 2,
);

if (response.success) {
  print('Test drive approved: ${response.message}');
} else {
  print('Error: ${response.message}');
}
```

### Reschedule Test Drive
```dart
final response = await ApiService().rescheduleTestDrive(
  testDriveId: 53,
  newDate: '2024-01-15',
  newTime: '14:30',
  reason: 'Driver unavailable at original time',
  employeeId: 2,
);

if (response.success) {
  print('Test drive rescheduled: ${response.message}');
} else {
  print('Error: ${response.message}');
}
```

## UI Features

### Approve Dialog
- Shows list of available drivers for the showroom
- Requires driver selection before approval
- Displays driver information (name, email)
- Shows confirmation message

### Reschedule Dialog
- Date picker for new test drive date
- Time picker for new test drive time
- Optional reason field for rescheduling
- Validation for required fields

### Error Handling
- Network error handling
- API error handling
- User data validation
- Graceful fallbacks for missing data

## Data Flow

1. **Load Pending Test Drives**: Fetches pending test drives from API
2. **Show Driver List**: Loads available drivers for the showroom
3. **User Selection**: User selects a driver and confirms approval
4. **API Call**: Calls approve API with test drive ID, driver ID, and employee ID
5. **Response Handling**: Shows success/error message based on API response
6. **Data Refresh**: Refreshes the pending test drives list

## Testing

A test file (`test_approve_test_drive_api.dart`) is provided to verify the API integration:
```dart
// Test approve test drive
await test('Approve test drive with driver assignment', () async {
  final response = await http.post(uri, headers: headers);
  expect(response.statusCode, 200);
  expect(responseData['success'], true);
  expect(responseData['message'], 'Test drive status updated to approved.');
});
```

## Configuration

The API configuration is managed in `lib/services/api_config.dart`:
- **Base URL**: `https://varenyam.acttconnect.com`
- **Approve Test Drive Endpoint**: `/api/textdrives/driver/status-update`
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

### Approve Functionality
- **Driver Assignment**: Assigns a specific driver to the test drive
- **Employee Tracking**: Records which employee approved the test drive
- **Status Update**: Changes test drive status from "pending" to "approved"
- **Real-time Updates**: Immediately reflects changes in the UI

### Reschedule Functionality
- **Date/Time Update**: Allows changing the test drive date and time
- **Reason Tracking**: Records the reason for rescheduling
- **Status Management**: Updates test drive status appropriately
- **User Notification**: Shows success/error messages

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
3. The driver must be available for the showroom
4. The employee ID must be valid
5. The test drive must be in "pending" status
6. Success response includes a confirmation message
7. Error responses include descriptive error messages

## API Examples

### Complete Approve Test Drive Request
```
POST https://varenyam.acttconnect.com/api/textdrives/driver/status-update?driver_id=3&status=approved&testdrive_id=53&employee_id=2
```

### Complete Reschedule Test Drive Request
```
POST https://varenyam.acttconnect.com/api/textdrives/driver/status-update?testdrive_id=53&status=rescheduled&new_date=2024-01-15&new_time=14:30&reschedule_reason=Driver%20unavailable&employee_id=2
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
2. **Push Notifications**: Add notifications for approved test drives
3. **Offline Support**: Cache pending test drives for offline viewing
4. **Batch Operations**: Allow approving multiple test drives at once
5. **Advanced Filtering**: Add filters for pending test drives
6. **Driver Availability**: Check driver availability before assignment 