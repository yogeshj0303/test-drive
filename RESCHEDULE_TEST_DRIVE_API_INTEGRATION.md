# Reschedule Test Drive API Integration

## Overview
This document describes the complete API integration for rescheduling test drives in the Varenium app. The reschedule functionality allows employees to reschedule pending test drive requests to a new date.

## API Endpoint

### Reschedule Test Drive
- **URL**: `https://varenyam.acttconnect.com/api/employee/textdrives/status-update`
- **Method**: POST
- **Headers**: 
  ```
  Content-Type: application/json
  Accept: application/json
  ```

## API Request Parameters

### Query Parameters
- `employee_id` (required): The ID of the employee rescheduling the test drive
- `status` (required): Must be "rescheduled" to reschedule the test drive
- `testdrive_id` (required): The ID of the test drive to reschedule
- `next_date` (required): The new date for the test drive (YYYY-MM-DD format)

## API Response Format

### Success Response
```json
{
    "success": true,
    "message": "Test drive status updated to rescheduled."
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
Updated the `rescheduleTestDrive` method:
```dart
Future<ApiResponse<String>> rescheduleTestDrive(int testDriveId, String newDate, int employeeId) async
```

### 2. Pending Test Drives Screen (`lib/screens/user/pending_test_drives_screen.dart`)
Updated to:
- Use the new API endpoint with employee ID
- Only require date selection (time is handled by showroom)
- Load user data from secure storage
- Handle API responses properly
- Show proper success/error messages
- Refresh data after successful rescheduling

## Usage Examples

### Reschedule Test Drive
```dart
final response = await ApiService().rescheduleTestDrive(
  testDriveId: 52,
  newDate: '2025-07-10',
  employeeId: 2,
);

if (response.success) {
  print('Test drive rescheduled: ${response.message}');
} else {
  print('Error: ${response.message}');
}
```

## UI Features

### Reschedule Dialog
- Shows date picker for new test drive date
- Removed time picker (time is arranged by showroom)
- Informational message about time arrangement
- Validation for required fields
- Loading state during API call

### Error Handling
- Network error handling
- API error handling
- User data validation
- Graceful fallbacks for missing data

## Data Flow

1. **User Action**: User clicks "Reschedule Test Drive" button
2. **Date Selection**: Shows dialog with date picker
3. **User Input**: User selects new date and confirms
4. **API Call**: Calls reschedule API with test drive ID, new date, and employee ID
5. **Response Handling**: Shows success/error message based on API response
6. **Data Refresh**: Refreshes the pending test drives list

## Key Changes from Previous Implementation

### Old Implementation
- **Endpoint**: `/api/textdrives/driver/status-update`
- **Parameters**: `testdrive_id`, `status`, `new_date`, `new_time`, `reschedule_reason`, `employee_id`
- **UI**: Date and time picker with reason field

### New Implementation
- **Endpoint**: `/api/employee/textdrives/status-update`
- **Parameters**: `employee_id`, `status`, `testdrive_id`, `next_date`
- **UI**: Date picker only with informational message

## Configuration

The API configuration is managed in `lib/services/api_config.dart`:
- **Base URL**: `https://varenyam.acttconnect.com`
- **Reschedule Test Drive Endpoint**: `/api/employee/textdrives/status-update`
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

### Reschedule Functionality
- **Employee Tracking**: Records which employee rescheduled the test drive
- **Date Update**: Changes the test drive date
- **Status Update**: Changes test drive status from "pending" to "rescheduled"
- **Time Management**: Time is handled by the showroom
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
7. Only date is required; time is managed by the showroom
8. The date format must be YYYY-MM-DD

## API Examples

### Complete Reschedule Test Drive Request
```
POST https://varenyam.acttconnect.com/api/employee/textdrives/status-update?employee_id=2&status=rescheduled&testdrive_id=52&next_date=2025-07-10
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
2. **Push Notifications**: Add notifications for rescheduled test drives
3. **Offline Support**: Cache pending test drives for offline viewing
4. **Batch Operations**: Allow rescheduling multiple test drives at once
5. **Advanced Filtering**: Add filters for pending test drives
6. **Date Validation**: Add business logic for valid reschedule dates
7. **Showroom Time Slots**: Integrate with showroom availability system 