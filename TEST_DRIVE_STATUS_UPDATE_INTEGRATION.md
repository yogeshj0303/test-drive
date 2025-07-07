# Test Drive Status Update API Integration

## Overview
This document describes the complete API integration for updating test drive statuses in the Varenium employee app.

## API Endpoints

### Update Test Drive Status
- **URL**: `https://varenyam.acttconnect.com/api/textdrives/driver/status-update`
- **Method**: POST
- **Headers**: 
  ```
  Content-Type: application/json
  Accept: application/json
  ```

## API Request Parameters

### Query Parameters
- `status` (required): The new status for the test drive
  - `completed` - Test drive has been completed
  - `canceled` - Test drive has been canceled
- `testdrive_id` (required): The ID of the test drive to update
- `driver_id` (required): The ID of the driver updating the status
- `cancel_description` (optional): Required when status is `canceled`

## API Response Format

### Success Response
```json
{
    "success": true,
    "message": "Test drive status updated to completed."
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

### 1. API Configuration (`lib/services/api_config.dart`)
Added the test drive status update endpoint:
```dart
static const String testDriveStatusUpdateEndpoint = '/api/textdrives/driver/status-update';
```

### 2. Employee API Service (`lib/services/employee_api_service.dart`)
Added the `updateTestDriveStatus` method:
```dart
Future<EmployeeApiResponse<Map<String, dynamic>>> updateTestDriveStatus({
  required int testDriveId,
  required int driverId,
  required String status,
  String? cancelDescription,
}) async
```

### 3. Update Status Screen (`lib/screens/employee/update_status_screen.dart`)
Completely rewritten to:
- Accept `AssignedTestDrive` parameter
- Use real API calls instead of mock data
- Handle different status types properly
- Validate cancellation reasons
- Show proper success/error messages

### 4. Assigned Test Drives Screen (`lib/screens/employee/assigned_test_drives_screen.dart`)
Updated to:
- Pass selected test drive data to UpdateStatusScreen
- Refresh data after returning from status update

## Usage Examples

### Update Status to Completed
```dart
final response = await EmployeeApiService().updateTestDriveStatus(
  testDriveId: 5,
  driverId: 3,
  status: 'completed',
);

if (response.success) {
  print('Status updated successfully: ${response.message}');
} else {
  print('Error: ${response.message}');
}
```

### Update Status to Canceled with Reason
```dart
final response = await EmployeeApiService().updateTestDriveStatus(
  testDriveId: 5,
  driverId: 3,
  status: 'canceled',
  cancelDescription: 'I\'m no longer available at the selected time',
);

if (response.success) {
  print('Test drive canceled: ${response.message}');
} else {
  print('Error: ${response.message}');
}
```



## UI Features

### Status Options
The UI provides two main status options for assigned test drives:
1. **Completed** (`completed`) - Green color with check icon
2. **Cancelled** (`canceled`) - Red color with cancel icon

**Note**: Assigned test drives can only be marked as completed or canceled. The "In Progress" status has been removed from the workflow.

### Form Validation
- **Cancellation Reason**: Required when status is set to "Cancelled"
- **Notes**: Optional for other statuses
- **Real-time Validation**: Form validates before submission

### User Experience
- **Loading States**: Shows loading indicator during API calls
- **Success Messages**: Displays success messages with green background
- **Error Handling**: Shows error messages with red background and dismiss option
- **Auto-refresh**: Automatically refreshes test drive list after status update
- **Navigation**: Proper back navigation and form state management

## Error Handling

The implementation includes comprehensive error handling for:
- **Network Errors**: No internet connection
- **Timeout Errors**: Request timeout (30 seconds)
- **Parsing Errors**: Invalid JSON response
- **API Errors**: Server-side errors with proper error messages
- **Validation Errors**: Form validation errors
- **Authentication Errors**: Missing employee data

## Security Features

1. **Parameter Validation**: All parameters are validated before API calls
2. **Error Sanitization**: Error messages are sanitized for security
3. **Required Fields**: Proper validation for required fields
4. **Status Mapping**: Proper mapping between UI status names and API values

## Testing

A test file (`test_test_drive_status_update.dart`) is provided to verify the API integration:
```dart
// Test completed status
await test('Update test drive status to completed', () async {
  final response = await apiService.updateTestDriveStatus(
    testDriveId: 5,
    driverId: 3,
    status: 'completed',
  );
  expect(response.success, true);
});

// Test canceled status with description
await test('Update test drive status to canceled with description', () async {
  final response = await apiService.updateTestDriveStatus(
    testDriveId: 5,
    driverId: 3,
    status: 'canceled',
    cancelDescription: 'I\'m no longer available at the selected time',
  );
  expect(response.success, true);
});
```

## Configuration

The API configuration is managed in `lib/services/api_config.dart`:
- **Base URL**: `https://varenyam.acttconnect.com`
- **Test Drive Status Update Endpoint**: `/api/textdrives/driver/status-update`
- **Method**: POST
- **Headers**: Standard JSON headers
- **Timeout**: 30 seconds

## Dependencies

Required dependencies in `pubspec.yaml`:
- `http: ^1.1.0` - For API calls
- `shared_preferences: ^2.2.2` - For local storage

## Notes

1. The API uses POST method for status updates
2. Cancellation requires a description when status is set to "canceled"
3. All status updates are logged for debugging purposes
4. The UI automatically refreshes after successful status updates
5. Error messages are user-friendly and actionable
6. The implementation supports all required status types
7. Form validation ensures data integrity before API calls
8. Loading states provide good user feedback during operations

## API Examples

### Complete Test Drive Status Update
```
POST https://varenyam.acttconnect.com/api/textdrives/driver/status-update?status=completed&testdrive_id=5&driver_id=3
```

### Canceled Test Drive with Description
```
POST https://varenyam.acttconnect.com/api/textdrives/driver/status-update?status=canceled&cancel_description=I'm%20no%20longer%20available%20at%20the%20selected%20time&testdrive_id=5&driver_id=3
```



## Troubleshooting

### Common Issues

1. **Network Error**: Check internet connection
2. **Timeout Error**: Server may be slow, retry the request
3. **Validation Error**: Ensure all required fields are filled
4. **Authentication Error**: Employee may need to login again
5. **API Error**: Check server logs for detailed error information

### Debug Information

The implementation includes comprehensive debug logging:
- API request URLs
- Request parameters
- Response status codes
- Response data
- Error messages

Enable debug mode to see detailed logs during development. 