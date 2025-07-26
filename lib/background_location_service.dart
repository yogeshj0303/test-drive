import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Future<void> initializeService(int testDriveId, int carId) async {
  try {
    final service = FlutterBackgroundService();

    // Check if service is already running
    final isRunning = await service.isRunning();
    if (isRunning) {
      print('Background service is already running');
      return;
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: false, // Set to false to avoid notification issues
        autoStart: false,
        notificationChannelId: 'location_tracking_channel',
        initialNotificationTitle: 'Test Drive Tracking',
        initialNotificationContent: 'Location tracking active for test drive #$testDriveId',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(),
    );
    
    await service.startService();
    // Send the IDs to the service after it starts
    service.invoke('setIds', {'testDriveId': testDriveId, 'carId': carId});
    print('Background service started successfully for test drive #$testDriveId');
  } catch (e) {
    print('Failed to start background service: $e');
    // Don't rethrow to prevent app crashes
  }
}

Future<void> stopService() async {
  try {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    print('Background service stop requested');
  } catch (e) {
    print('Failed to stop background service: $e');
  }
}

Future<bool> isServiceRunning() async {
  try {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  } catch (e) {
    print('Failed to check service status: $e');
    return false;
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  int? testDriveId;
  int? carId;

  service.on('setIds').listen((event) {
    testDriveId = event!['testDriveId'];
    carId = event['carId'];
    print('Received IDs: testDriveId=$testDriveId, carId=$carId');
  });

  service.on('stopService').listen((event) {
    print('Stopping background service');
    service.stopSelf();
  });

  // Timer to send location updates every 10 seconds
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      if (testDriveId == null || carId == null) {
        print('Missing testDriveId or carId');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();
      print('📍 Background location update: ${position.latitude}, ${position.longitude}');
      
      // Send to API
      final response = await http.post(
        Uri.parse('https://varenyam.acttconnect.com/api/update-location'),
        body: {
          'testdrive_id': testDriveId.toString(),
          'car_id': carId.toString(),
          'car_latitude': position.latitude.toString(),
          'car_longitude': position.longitude.toString(),
          'tracking_id': 'track_001',
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ Background location sent successfully for test drive #$testDriveId');
      } else {
        print('❌ Failed to send background location: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error in background service: $e');
    }
  });
} 