# Varenium - Car Test Drive Management App

A professional car test drive management application built with Flutter.

## Features

- **User Management**: Separate interfaces for users and employees
- **Test Drive Management**: Request, schedule, and track test drives
- **Location Tracking**: Real-time location tracking for employees (no API key required)
- **Modern UI**: Beautiful and intuitive user interface
- **Cross-platform**: Works on Android, iOS, and Web

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.2.3)
- Dart SDK
- Android Studio / VS Code

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd varenium
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Location Tracking

The app includes a location tracking feature that works without any API keys:

- **GPS Location**: Uses device GPS to get current coordinates
- **Address Lookup**: Attempts to get address from coordinates (requires internet)
- **Visual Map**: Shows current location on a simple map interface
- **Location History**: Displays previous location points
- **Real-time Updates**: Continuously updates location when tracking is active

### Location Permissions

The app requires the following permissions:
- `ACCESS_FINE_LOCATION`: For precise GPS location
- `ACCESS_COARSE_LOCATION`: For approximate location
- `INTERNET`: For address lookup
- `ACCESS_NETWORK_STATE`: For network connectivity checks

## Troubleshooting

### Flogger Logs Issue
If you see "Too many Flogger logs received before configuration" warnings:

1. This is a common Android logging issue that doesn't affect app functionality
2. The warnings are from Google Play Services and can be safely ignored
3. To reduce these warnings, ensure you have proper internet connectivity

### Location Services Not Working
If location tracking fails:

1. Ensure location permissions are granted
2. Check that GPS is enabled on the device
3. Verify internet connectivity for address lookup
4. The app will show coordinates even if address lookup fails

### Address Lookup Failed
If address lookup fails:

1. Check internet connectivity
2. The geocoding service might be temporarily unavailable
3. The app will show coordinates even if address lookup fails
4. This is normal behavior and doesn't affect core functionality

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
│   ├── employee/            # Employee-specific screens
│   ├── user/                # User-specific screens
│   └── splash_screen.dart   # Splash screen
├── services/                # Business logic services
├── theme/                   # App theming
└── widgets/                 # Reusable widgets
```

## Dependencies

- `geolocator`: Location services
- `geocoding`: Address lookup
- `permission_handler`: Permission management
- `shared_preferences`: Local storage
- `google_fonts`: Custom fonts

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License.
#   t e s t - d r i v e  
 