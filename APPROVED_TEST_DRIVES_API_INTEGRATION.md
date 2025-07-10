# Approved Test Drives API Integration

## Overview
This document describes the complete API integration for fetching approved test drives in the Varenium user app.

## API Endpoint

### Fetch Approved Test Drives
- **URL**: `https://varenyam.acttconnect.com/api/employee/textdrives_with_status`
- **Method**: POST
- **Headers**: 
  ```
  Content-Type: application/json
  Accept: application/json
  ```

## API Request Parameters

### Request Body
```json
{
  "users_id": 2,
  "status": "approved"
}
```

### Parameters
- `users_id` (required): The ID of the user whose approved test drives to fetch
- `status` (required): Must be "approved" to fetch approved test drives

## API Response Format

### Success Response
```json
{
    "success": true,
    "message": "Test drives fetched successfully.",
    "data": [
        {
            "id": 50,
            "created_at": "2025-07-08T11:59:56.000000Z",
            "updated_at": "2025-07-09T06:54:38.000000Z",
            "car_id": 3,
            "front_user_id": 3,
            "date": "2025-06-21",
            "time": "10:32:00",
            "pickup_address": "ashoka bhopal",
            "pickup_city": "bhopal",
            "pickup_pincode": "462023",
            "driving_license": "1231231231212",
            "aadhar_no": "123412341234",
            "note": "sadsasad",
            "status": "approved",
            "showroom_id": "1",
            "reject_description": null,
            "approved_employee_id": 2,
            "cancel_description": null,
            "cancel_date_time": null,
            "driver_id": null,
            "driver_update_date": null,
            "approver_or_reject_by": 2,
            "approved_or_reject_date": "2025-07-09 06:54:38",
            "user_name": "Aishwarya",
            "user_mobile": "9090909090",
            "user_email": "newuser@gmail.com",
            "user_adhar": "324232323",
            "rescheduled_by": null,
            "rescheduled_date": null,
            "car": {
                "id": 3,
                "ratting": 4,
                "name": "Altroz",
                "model_number": "Altroz",
                "showroom_id": 2,
                "status": "active",
                "main_image": "assets/car_images/main/1750420703_mK6JwDEm8T.avif",
                "year_of_manufacture": 2025,
                "color": "Dune Glow , Pristine White, Royal blue ,Ember glow ,Pure gray,",
                "vin": null,
                "fuel_type": "diesel",
                "transmission": "automatic",
                "drivetrain": "AWD",
                "seating_capacity": 6,
                "engine_capacity": null,
                "horsepower": null,
                "torque": null,
                "body_type": "adasd",
                "condition": "used",
                "stock_number": null,
                "registration_number": null,
                "description": "...",
                "features": null,
                "availability_date": null,
                "next_service_date": null,
                "created_by": null,
                "updated_by": null,
                "created_at": "2025-06-20T11:58:23.000000Z",
                "updated_at": "2025-06-20T11:59:16.000000Z",
                "images": [...],
                "showroom": {
                    "id": 2,
                    "auth_id": 1,
                    "name": "varenyam kolar",
                    "address": "bhopal",
                    "city": "Bhopal",
                    "state": "Madhya Pradesh",
                    "district": "Bhopal",
                    "pincode": "462023",
                    "showroom_image": "assets/showroom/1751880859_686b949be36d9.jpeg",
                    "ratting": 4,
                    "password_word": null,
                    "created_at": "2025-06-17T08:40:08.000000Z",
                    "updated_at": "2025-07-07T09:34:19.000000Z",
                    "location_type": "showroom",
                    "longitude": "23.2141799",
                    "latitude": "77.4756307"
                }
            },
            "requestby_emplyee": {...},
            "approver_rejecter": {
                "id": 2,
                "name": "Aish",
                "email": "aish@gmail.com",
                "aadhar_no": null,
                "driving_license_no": null,
                "email_verified_at": null,
                "is_admin": "employee",
                "status": "active",
                "role_id": 2,
                "showroom_id": 1,
                "mobile_no": "9999999999",
                "avatar": "assets/profile/1750153119_6851379f63da2.jpg",
                "created_at": "2025-06-17T09:38:39.000000Z",
                "updated_at": "2025-07-04T05:12:18.000000Z",
                "avatar_url": "https://varenyam.acttconnect.com/assets/profile/1750153119_6851379f63da2.jpg"
            },
            "rescheduler": null
        }
    ]
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
Added the `getUserApprovedTestDrives` method:
```dart
Future<ApiResponse<List<TestDriveListResponse>>> getUserApprovedTestDrives(int userId) async
```

### 2. Approved Test Drives Screen (`lib/screens/user/approved_test_drives_screen.dart`)
Completely updated to:
- Use real API calls instead of dummy data
- Load user data from secure storage
- Handle API responses properly
- Show detailed approval information
- Display approver details
- Show driver assignment information
- Handle errors gracefully

## Key Features

### Data Loading
- Loads current user data from secure storage
- Fetches approved test drives from API
- Handles loading states and error scenarios
- Supports pull-to-refresh functionality

### UI Enhancements
- Shows approval date and time
- Displays who approved the test drive
- Shows driver assignment information if available
- Enhanced detail view with all relevant information
- Contact showroom functionality
- Reschedule functionality

### Error Handling
- Network error handling
- API error handling
- User data validation
- Graceful fallbacks for missing data

## Data Model

The integration uses the existing `TestDriveListResponse` model which includes:
- Basic test drive information
- Car details with images and showroom info
- User information
- Employee information (requestby, approver)
- Approval details (approved_employee_id, approved_or_reject_date, approver_rejecter)
- Driver assignment details (driver_id, driver_update_date)

## Testing

A test file (`test_approved_test_drives_api.dart`) is provided to verify the API integration:
```dart
// Test fetching approved test drives
await test('Fetch approved test drives for user ID 2', () async {
  final response = await http.post(uri, body: jsonEncode({
    'users_id': 2,
    'status': 'approved',
  }));
  expect(response.statusCode, 200);
  // ... more assertions
});
```

## Configuration

The API configuration is managed in `lib/services/api_config.dart`:
- **Base URL**: `https://varenyam.acttconnect.com`
- **Approved Test Drives Endpoint**: `/api/employee/textdrives_with_status`
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

## Key Differences from Rescheduled Test Drives

### Approved Test Drives Features:
- **Approval Information**: Shows who approved and when
- **Driver Assignment**: Shows if a driver has been assigned
- **No Rescheduling Info**: Approved drives don't have rescheduling details
- **Status**: Always "approved"

### Rescheduled Test Drives Features:
- **Rescheduling Information**: Shows who rescheduled and when
- **Cancellation Reason**: Shows why the original request was cancelled
- **No Driver Assignment**: Rescheduled drives may not have drivers assigned yet
- **Status**: Always "rescheduled"

## Notes

1. The API uses POST method for fetching approved test drives
2. The status parameter must be exactly "approved"
3. The API returns comprehensive data including car, showroom, and user details
4. Approved test drives may have driver assignments
5. The approver information is included in the response
6. The API supports empty results for users with no approved test drives

## Future Enhancements

1. **Real-time Updates**: Implement WebSocket for real-time status updates
2. **Push Notifications**: Add notifications for new approved test drives
3. **Offline Support**: Cache approved test drives for offline viewing
4. **Advanced Filtering**: Add date range and status filtering options
5. **Export Functionality**: Allow users to export their approved test drives
6. **Driver Contact**: Add ability to contact assigned drivers directly
7. **Test Drive Reminders**: Send reminders before scheduled test drives 