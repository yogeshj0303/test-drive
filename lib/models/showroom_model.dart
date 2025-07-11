class Showroom {
  final int id;
  final int authId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String district;
  final String pincode;
  final String? showroomImage;
  final int ratting;
  final String? passwordWord;
  final String createdAt;
  final String updatedAt;
  final String? locationType;
  final String? longitude;
  final String? latitude;

  Showroom({
    required this.id,
    required this.authId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.district,
    required this.pincode,
    this.showroomImage,
    required this.ratting,
    this.passwordWord,
    required this.createdAt,
    required this.updatedAt,
    this.locationType,
    this.longitude,
    this.latitude,
  });

  factory Showroom.fromJson(Map<String, dynamic> json) {
    try {
      return Showroom(
        id: json['id'] ?? 0,
        authId: json['auth_id'] ?? 0,
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        district: json['district'] ?? '',
        pincode: json['pincode'] ?? '',
        showroomImage: json['showroom_image'],
        ratting: json['ratting'] ?? 0,
        passwordWord: json['password_word'],
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        locationType: json['location_type'],
        longitude: json['longitude'],
        latitude: json['latitude'],
      );
    } catch (e) {
      print('Error parsing Showroom: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auth_id': authId,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'district': district,
      'pincode': pincode,
      'showroom_image': showroomImage,
      'ratting': ratting,
      'password_word': passwordWord,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'location_type': locationType,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  // Helper method to get full address
  String get fullAddress {
    return '$address, $city, $state - $pincode';
  }

  // Helper method to get location display
  String get locationDisplay {
    return '$city, $state';
  }
} 