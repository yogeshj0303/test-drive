# Employee Profile API Integration

## Overview
This document describes the API integration for the Employee Profile Screen in the Varenium Flutter app.

## UI Improvements & Alignment

### Screen Layout Enhancements
- **Proper App Bar**: Added transparent app bar with back button and refresh action
- **Better Positioning**: Fixed profile header positioning to respect status bar
- **Consistent Spacing**: Improved padding and margins throughout the screen
- **Compact Design**: Streamlined profile header layout for better visual hierarchy

### Why Floating Action Button Was Removed
The floating action button was removed for the following reasons:
1. **Redundant Functionality**: Pull-to-refresh already provides the same refresh capability
2. **Better UX**: App bar refresh button is more discoverable and follows Material Design guidelines
3. **Cleaner Interface**: Removes visual clutter and provides more space for content
4. **Consistent Navigation**: App bar actions are more intuitive for users

### Alternative Refresh Methods
- **Pull-to-Refresh**: Swipe down on the screen to refresh data
- **App Bar Button**: Tap the refresh icon in the top-right corner
- **Automatic Refresh**: Data refreshes when the screen is first loaded

## API Endpoint
- **URL**: `https://varenyam.acttconnect.com/api/driver/profile/{employee_id}`
- **Method**: GET
- **Authentication**: Not required (uses employee ID from stored data)

## API Response Format
```json
{
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

### 1. API Configuration
- Added `employeeProfileEndpoint` to `lib/services/api_config.dart`
- Endpoint: `/api/driver/profile`

### 2. Data Models
- **EmployeeProfileResponse**: Wrapper for the API response
- **Employee**: Employee data model (already existed)
- **EmployeeDocument**: Document data model (already existed)

### 3. API Service
- Added `getProfile(int employeeId)` method to `EmployeeApiService`
- Handles network errors, timeouts, and response parsing
- Returns `EmployeeApiResponse<EmployeeProfileResponse>`

### 4. Profile Screen Integration
- **Loading State**: Shows loading indicator while fetching data
- **Error Handling**: Displays error messages with retry functionality
- **Data Display**: Shows real employee data including:
  - Name, email, mobile number
  - Profile avatar (with fallback to default icon)
  - Documents list (if available)
- **Refresh Functionality**: 
  - Pull-to-refresh gesture
  - App bar refresh button
- **Offline Support**: Uses cached data if API fails

### 5. Features Implemented

#### App Bar
- Transparent background that blends with the gradient header
- Back button for navigation
- Refresh button for manual data refresh
- Proper status bar handling

#### Profile Header
- Displays employee avatar (from API or default icon)
- Shows employee name, email, and mobile number
- Handles image loading errors gracefully
- Compact and centered layout

#### Documents Section
- Displays employee documents if available
- Shows document type with appropriate icons
- Displays creation date
- Placeholder for document opening functionality

#### Performance & Work Statistics
- Currently shows static data (can be enhanced with real API data)
- Performance metrics cards
- Work statistics grid

#### Settings Section
- Personal Information navigation
- Change Password navigation
- About screen navigation

#### Logout Functionality
- Confirmation dialog
- Clears stored employee data
- Navigates to login screen

## Usage

### Fetching Profile Data
```dart
final apiResponse = await EmployeeApiService().getProfile(employeeId);
if (apiResponse.success && apiResponse.data != null) {
  final employee = apiResponse.data!.user;
  // Use employee data
}
```

### Refreshing Profile
```dart
// Pull-to-refresh or app bar button
await _refreshProfile();
```

## Error Handling
- Network connectivity issues
- API server errors
- Invalid response format
- Timeout handling
- Graceful fallback to cached data

## Future Enhancements
1. **Real Performance Data**: Integrate with performance metrics API
2. **Document Viewer**: Implement document opening functionality
3. **Profile Updates**: Add profile editing capabilities
4. **Push Notifications**: Real-time profile updates
5. **Offline Mode**: Enhanced offline data management

## Testing
The integration includes:
- Loading states
- Error states with retry functionality
- Success states with data display
- Pull-to-refresh functionality
- App bar refresh button

## Dependencies
- `http` package for API calls
- `shared_preferences` for data storage
- Flutter built-in widgets for UI 