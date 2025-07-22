import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSetupPage extends StatefulWidget {
  final GlobalKey<LocationSetupPageState> key;
  LocationSetupPage({required this.key});

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

  @override
  void initState() {
    super.initState();
    _determinePosition();
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
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: _initialCameraPosition,
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,
                    myLocationEnabled: true,
                    markers: {
                      if (_currentPosition != null)
                        Marker(
                          markerId: MarkerId('currentLocation'),
                          position: _currentPosition!,
                          infoWindow: InfoWindow(title: 'Your Location'),
                        ),
                    },
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
                  ),
                  margin: const EdgeInsets.all(16.0),
                  color: theme.colorScheme.surface,
                  elevation: 0,
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
                            : Text(_currentAddress, style: theme.textTheme.bodyMedium),
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