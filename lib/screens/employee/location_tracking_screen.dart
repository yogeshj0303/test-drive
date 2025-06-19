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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    _updateAddress(LatLng(position.latitude, position.longitude));
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _currentPosition = position;
        _currentAddress =
            "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
        _isLoading = false; // Stop loading once the address is fetched
      });
    } catch (e) {
      print(e);
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

  void _updatePosition(CameraPosition position) {
    _updateAddress(position.target);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location Setup'),
        backgroundColor: Colors.amber,
      ),
      body: _isLoading || _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: CameraPosition(
                      target: _currentPosition!,
                      zoom: 14.0,
                    ),
                    onCameraMove: _updatePosition,
                    myLocationEnabled: true,
                    markers: {
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
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.amber),
                  ),
                  margin: EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Address:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(_currentAddress),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Handle location confirmation
                          },
                          child: Text('Confirm Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
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