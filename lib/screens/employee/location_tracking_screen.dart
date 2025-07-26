import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async'; // Added for Timer
import 'dart:convert'; // Added for jsonDecode
import 'package:http/http.dart' as http; // Added for http
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;

Future<BitmapDescriptor> bitmapDescriptorFromIconData(
  IconData iconData, {
  Color color = Colors.red,
  double size = 64,
}) async {
  final pictureRecorder = ui.PictureRecorder();
  final canvas = Canvas(pictureRecorder);

  // Draw shadow ellipse
  final shadowPaint = Paint()..color = Colors.black.withOpacity(0.3);
  canvas.drawOval(
    Rect.fromCenter(
      center: Offset(size / 2, size * 0.85),
      width: size * 0.6,
      height: size * 0.18,
    ),
    shadowPaint,
  );

  // Draw the car icon with drop shadow
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  textPainter.text = TextSpan(
    text: String.fromCharCode(iconData.codePoint),
    style: TextStyle(
      fontSize: size,
      fontFamily: iconData.fontFamily,
      color: color,
      package: iconData.fontPackage,
      shadows: [
        Shadow(
          blurRadius: 4,
          color: Colors.black.withOpacity(0.4),
          offset: Offset(2, 2),
        ),
      ],
    ),
  );
  textPainter.layout();
  textPainter.paint(canvas, Offset(0, 0));

  final image = await pictureRecorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

class LocationSetupPage extends StatefulWidget {
  final GlobalKey<LocationSetupPageState> key;
  final double? carLongitude;
  final double? carLatitude;
  final int? carId; // <-- Added
  final int? testDriveId; // <-- Added
  LocationSetupPage({required this.key, this.carLongitude, this.carLatitude, this.carId, this.testDriveId});

  @override
  LocationSetupPageState createState() => LocationSetupPageState();
}

class LocationSetupPageState extends State<LocationSetupPage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  String _currentAddress = "Fetching location...";
  bool _isLoading = true;
  bool _isAddressLoading = false;
  String? _errorMessage;
  static const LatLng _defaultLatLng = LatLng(19.0760, 72.8777); // Mumbai
  BitmapDescriptor? _carIcon;
  bool _hasTrackingData = false;
  List<LatLng> _pathPoints = [];
  LatLng? _initialCarPosition;
  String? _initialCarAddress;
  
  // Timer for polling
  @override
  void initState() {
    super.initState();
    print('LocationSetupPage: carId = ${widget.carId}, testDriveId = ${widget.testDriveId}'); // Debug print
    _loadCarMarker();
    // Always set initial position to car coordinates if available
    if (widget.carLatitude != null && widget.carLongitude != null) {
      _initialCarPosition = LatLng(widget.carLatitude!, widget.carLongitude!);
      _currentPosition = _initialCarPosition;
      _pathPoints = [_currentPosition!];
      _isLoading = false;
      _errorMessage = null;
      _setInitialCarAddress(_currentPosition!);
    }
    if (widget.carId == null || widget.carId == 0 || widget.testDriveId == null || widget.testDriveId == 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid car or test drive ID. Cannot track location.';
      });
      return;
    }
    if (widget.carId != null && widget.testDriveId != null) {
      _fetchAndTrackCarLocation();
    } else if (widget.carLatitude != null && widget.carLongitude != null) {
      // Already handled above
    } else {
      _determinePosition();
    }
  }

  Future<void> _loadCarMarker() async {
    final icon = await bitmapDescriptorFromIconData(
      Icons.directions_car,
      color: Colors.red,
      size: 64,
    );
    setState(() {
      _carIcon = icon;
    });
  }

  // Polling logic
  Timer? _pollingTimer;
  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAndTrackCarLocation() async {
    await _fetchCarLocation();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 10), (_) => _fetchCarLocation());
  }

  Future<void> _setInitialCarAddress(LatLng position) async {
    setState(() {
      _isAddressLoading = true;
      _errorMessage = null;
    });
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();
      setState(() {
        _initialCarAddress =
            "${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}";
        _currentAddress = _initialCarAddress!;
      });
    } catch (e) {
      setState(() {
        _initialCarAddress = "Unable to fetch address.";
        _currentAddress = _initialCarAddress!;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isAddressLoading = false;
      });
    }
  }

  Future<void> _fetchCarLocation() async {
    final isFirstLoad = !_hasTrackingData && _currentPosition == null;
    if (isFirstLoad) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
    try {
      final carId = widget.carId;
      final testDriveId = widget.testDriveId;
      if (carId == null || testDriveId == null) return;
      final url = Uri.parse('https://varenyam.acttconnect.com/api/get-location?testdrive_id=' + testDriveId.toString() + '&car_id=' + carId.toString());
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List && data['data'].isNotEmpty) {
          // Parse all points for the polyline
          final points = (data['data'] as List)
              .map<LatLng>((item) => LatLng(
                    double.parse(item['latitude'].toString()),
                    double.parse(item['longitude'].toString()),
                  ))
              .toList();
          // Use the last point as the current position
          final latest = points.last;
          setState(() {
            _currentPosition = latest;
            _pathPoints = points;
            _isLoading = false;
            _hasTrackingData = true;
          });
          _updateAddress(_currentPosition!);
          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
          }
          return;
        }
        // If no tracking data, but car coordinates are available, show those
        if (widget.carLatitude != null && widget.carLongitude != null) {
          setState(() {
            _currentPosition = LatLng(widget.carLatitude!, widget.carLongitude!);
            if (_pathPoints.isEmpty) _pathPoints = [_currentPosition!];
            _isLoading = false;
            _errorMessage = null;
            _hasTrackingData = false;
          });
          // Only set the address to the initial car address
          if (_initialCarAddress != null) {
            setState(() {
              _currentAddress = _initialCarAddress!;
            });
          } else {
            _setInitialCarAddress(_currentPosition!);
          }
          if (_mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
          }
        } else {
          setState(() {
            _errorMessage = 'No tracking data or car coordinates available.';
            _isLoading = false;
            _hasTrackingData = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch location.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Showing default location.');
      }
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Showing default location.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Showing default location.');
      }
      Position position = await Geolocator.getCurrentPosition();
      await _updateAddress(LatLng(position.latitude, position.longitude));
    } catch (e) {
      setState(() {
        _currentPosition = _defaultLatLng;
        _currentAddress = "Default Location (Mumbai, India)";
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    setState(() {
      _isAddressLoading = true;
      _errorMessage = null;
    });
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      Placemark place = placemarks.isNotEmpty ? placemarks[0] : Placemark();
      setState(() {
        _currentPosition = position;
        _currentAddress =
            "${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}, ${place.country ?? ''}";
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Unable to fetch address.";
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isAddressLoading = false;
      });
    }
  }

  LatLng? getCurrentPosition() {
    return _currentPosition;
  }

  String getCurrentAddress() {
    return _currentAddress;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  }

  CameraPosition get _initialCameraPosition => CameraPosition(
        target: _currentPosition ?? _defaultLatLng,
        zoom: 14.0,
      );

  LatLng? _lastCameraPosition;
  void _onCameraMove(CameraPosition position) {
    _lastCameraPosition = position.target;
  }

  void _onCameraIdle() {
    if (_lastCameraPosition != null) {
      _updateAddress(_lastCameraPosition!);
    }
  }

  void _recenterToCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    await _determinePosition();
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Location Tracking',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading || _currentPosition == null
          ? (_errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : Center(child: CircularProgressIndicator()))
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: _initialCameraPosition,
                    onCameraMove: _onCameraMove,
                    myLocationEnabled: true,
                    markers: {
                      if (!_hasTrackingData && widget.carLatitude != null && widget.carLongitude != null)
                        Marker(
                          markerId: MarkerId('initialLocation'),
                          position: LatLng(widget.carLatitude!, widget.carLongitude!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: InfoWindow(title: 'Initial Car Location'),
                        ),
                      if (_hasTrackingData && _currentPosition != null)
                        Marker(
                          markerId: MarkerId('currentLocation'),
                          position: _currentPosition!,
                          icon: _carIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                          infoWindow: InfoWindow(title: _errorMessage == null ? 'Your Location' : 'Last Known Car Location'),
                        ),
                      if (_hasTrackingData && widget.carLatitude != null && widget.carLongitude != null)
                        Marker(
                          markerId: MarkerId('initialLocation'),
                          position: LatLng(widget.carLatitude!, widget.carLongitude!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                          infoWindow: InfoWindow(title: 'Initial Car Location'),
                        ),
                    },
                    polylines: {
                      if (_pathPoints.length > 1)
                        Polyline(
                          polylineId: PolylineId('car_path'),
                          points: _pathPoints,
                          color: Colors.blue,
                          width: 5,
                        ),
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: theme.colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Address',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _isAddressLoading
                            ? Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Fetching address...', style: theme.textTheme.bodyMedium),
                                ],
                              )
                            : SelectableText(
                                _currentAddress,
                                style: theme.textTheme.bodyMedium,
                                maxLines: null,
                              ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 