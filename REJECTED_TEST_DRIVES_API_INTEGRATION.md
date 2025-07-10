# Rejected Test Drives API Integration

## Overview
This document describes the integration of the rejected test drives API in the Varenium Flutter app. The API fetches test drives that have been rejected by the showroom or admin.

## API Details

### Endpoint
- **URL**: `https://varenyam.acttconnect.com/api/employee/textdrives_with_status`
- **Method**: POST
- **Content-Type**: application/json

### Request Parameters
```json
{
  "users_id": 2,
  "status": "rejected"
}
```

### Response Format
```json
{
  "success": true,
  "message": "Test drives fetched successfully.",
  "data": [
    {
      "id": 51,
      "status": "rejected",
      "reject_description": "asdasdasd as d asdasd",
      "approved_or_reject_date": "2025-07-09 06:50:18",
      "approver_rejecter": {
        "id": 1,
        "name": "admin",
        "email": "admin@themesbrand.com"
      },
      "car": {
        "id": 3,
        "name": "Altroz",
        "model_number": "Altroz"
      },
      "showroom": {
        "id": 2,
        "name": "varenyam kolar",
        "city": "Bhopal",
        "state": "Madhya Pradesh"
      }
    }
  ]
}
```

## Implementation Details

### Files Modified

1. **`lib/services/api_service.dart`**
   - Added `getUserRejectedTestDrives(int userId)` method
   - Uses the same endpoint as rescheduled/approved test drives but with `status: 'rejected'`

2. **`lib/screens/user/cancel_test_drive_screen.dart`**
   - Updated to use `getUserRejectedTestDrives()` instead of `getUserCanceledTestDrives()`
   - Changed UI labels from "Canceled" to "Rejected"
   - Updated to use `reject_description` field instead of `cancel_description`
   - Added rejection date display using `approved_or_reject_date`
   - Added "Rejected By" section showing approver/rejecter details

### Key Features

1. **Status Display**: Shows "REJECTED" status badge
2. **Rejection Details**: Displays rejection reason and date
3. **Rejecter Information**: Shows who rejected the test drive
4. **Car Information**: Displays car details and showroom information
5. **Error Handling**: Proper error handling for network issues and API errors
6. **Loading States**: Loading indicators and empty state handling
7. **Refresh Functionality**: Pull-to-refresh and manual refresh options

### UI Enhancements

1. **Modern Design**: Clean, modern UI with proper spacing and colors
2. **Status Colors**: Red color scheme for rejected status
3. **Detail View**: Comprehensive modal bottom sheet with all rejection details
4. **Empty State**: User-friendly empty state when no rejected test drives exist
5. **Error States**: Clear error messages with retry functionality

### Data Mapping

The API response maps to the existing `TestDriveListResponse` model:
- `reject_description` → `rejectDescription`
- `approved_or_reject_date` → `approvedOrRejectDate`
- `approver_rejecter` → `approverRejecter`
- `status` → `status` (shows as "rejected")

### Error Handling

1. **Network Errors**: Shows network error message with retry option
2. **API Errors**: Displays server error messages
3. **User Not Found**: Handles case when user data is not available
4. **Empty Data**: Gracefully handles empty response arrays

### Testing

A test file `test_rejected_test_drives_api.dart` is included to verify:
- API endpoint functionality
- Response format validation
- Error handling for invalid parameters
- Data structure verification

## Usage

The rejected test drives screen is accessible from the main user navigation and displays all test drives that have been rejected by the showroom or admin. Users can:

1. View list of rejected test drives
2. Tap on any test drive to see detailed information
3. View rejection reason and who rejected it
4. Refresh the list to get latest data
5. See car and showroom details for each rejected test drive

## Differences from Canceled Test Drives

- **Status**: Uses "rejected" instead of "canceled"
- **API Field**: Uses `reject_description` instead of `cancel_description`
- **Date Field**: Uses `approved_or_reject_date` instead of `cancel_date_time`
- **Action**: Shows who rejected instead of who canceled
- **UI Labels**: All labels updated to reflect "rejected" status

## Future Enhancements

1. **Re-request Functionality**: Allow users to request the same test drive again
2. **Contact Rejecter**: Direct contact option for the person who rejected
3. **Appeal Process**: Option to appeal rejection decisions
4. **Notifications**: Push notifications for new rejections
5. **Analytics**: Track rejection reasons and patterns 