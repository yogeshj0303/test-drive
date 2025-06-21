import 'car_model.dart';
import 'showroom_model.dart';
import 'user_model.dart';

class TestDriveCar {
  final int id;
  final String name;
  final String modelNumber;
  final int showroomId;
  final String status;
  final String mainImage;
  final int yearOfManufacture;
  final String color;
  final String? vin;
  final String fuelType;
  final String transmission;
  final String? drivetrain;
  final int seatingCapacity;
  final String? engineCapacity;
  final String? horsepower;
  final String? torque;
  final String? bodyType;
  final String condition;
  final String? stockNumber;
  final String? registrationNumber;
  final String? description;
  final String? features;
  final String? availabilityDate;
  final String? nextServiceDate;
  final String? createdBy;
  final String? updatedBy;
  final String createdAt;
  final String updatedAt;
  final List<CarImage> images;
  final Showroom showroom;
  final int? ratting;

  TestDriveCar({
    required this.id,
    required this.name,
    required this.modelNumber,
    required this.showroomId,
    required this.status,
    required this.mainImage,
    required this.yearOfManufacture,
    required this.color,
    this.vin,
    required this.fuelType,
    required this.transmission,
    this.drivetrain,
    required this.seatingCapacity,
    this.engineCapacity,
    this.horsepower,
    this.torque,
    this.bodyType,
    required this.condition,
    this.stockNumber,
    this.registrationNumber,
    this.description,
    this.features,
    this.availabilityDate,
    this.nextServiceDate,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.images,
    required this.showroom,
    this.ratting,
  });

  factory TestDriveCar.fromJson(Map<String, dynamic> json) {
    try {
      return TestDriveCar(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        modelNumber: json['model_number'] as String? ?? '',
        showroomId: json['showroom_id'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        mainImage: json['main_image'] as String? ?? '',
        yearOfManufacture: json['year_of_manufacture'] as int? ?? 0,
        color: json['color'] as String? ?? '',
        vin: json['vin'] as String?,
        fuelType: json['fuel_type'] as String? ?? '',
        transmission: json['transmission'] as String? ?? '',
        drivetrain: json['drivetrain'] as String?,
        seatingCapacity: json['seating_capacity'] as int? ?? 0,
        engineCapacity: json['engine_capacity']?.toString(),
        horsepower: json['horsepower']?.toString(),
        torque: json['torque']?.toString(),
        bodyType: json['body_type'] as String?,
        condition: json['condition'] as String? ?? '',
        stockNumber: json['stock_number']?.toString(),
        registrationNumber: json['registration_number']?.toString(),
        description: json['description'] as String?,
        features: json['features'] as String?,
        availabilityDate: json['availability_date'] as String?,
        nextServiceDate: json['next_service_date'] as String?,
        createdBy: json['created_by']?.toString(),
        updatedBy: json['updated_by']?.toString(),
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        images: (json['images'] as List<dynamic>?)
                ?.map((imageJson) => CarImage.fromJson(imageJson as Map<String, dynamic>))
                .toList() ??
            [],
        showroom: Showroom.fromJson(json['showroom'] as Map<String, dynamic>),
        ratting: json['ratting'] as int?,
      );
    } catch (e) {
      print('Error parsing TestDriveCar: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class CarImage {
  final int id;
  final int carId;
  final String imagePath;
  final String createdAt;
  final String updatedAt;

  CarImage({
    required this.id,
    required this.carId,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CarImage.fromJson(Map<String, dynamic> json) {
    try {
      return CarImage(
        id: json['id'] as int? ?? 0,
        carId: json['car_id'] as int? ?? 0,
        imagePath: json['image_path'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
    } catch (e) {
      print('Error parsing CarImage: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class TestDriveRequest {
  final int carId;
  final int frontUserId;
  final String date;
  final String time;
  final String pickupAddress;
  final String pickupCity;
  final String pickupPincode;
  final String drivingLicense;
  final String aadharNo;
  final String note;
  final String status;
  final int showroomId;

  TestDriveRequest({
    required this.carId,
    required this.frontUserId,
    required this.date,
    required this.time,
    required this.pickupAddress,
    required this.pickupCity,
    required this.pickupPincode,
    required this.drivingLicense,
    required this.aadharNo,
    required this.note,
    required this.status,
    required this.showroomId,
  });

  Map<String, dynamic> toJson() {
    return {
      'car_id': carId.toString(),
      'front_user_id': frontUserId.toString(),
      'date': date,
      'time': time,
      'pickup_address': pickupAddress,
      'pickup_city': pickupCity,
      'pickup_pincode': pickupPincode,
      'driving_license': drivingLicense,
      'aadhar_no': aadharNo,
      'note': note,
      'status': status,
      'showroom_id': showroomId.toString(),
    };
  }

  Map<String, String> toQueryParameters() {
    return {
      'car_id': carId.toString(),
      'front_user_id': frontUserId.toString(),
      'date': date,
      'time': time,
      'pickup_address': pickupAddress,
      'pickup_city': pickupCity,
      'pickup_pincode': pickupPincode,
      'driving_license': drivingLicense,
      'aadhar_no': aadharNo,
      'note': note,
      'status': status,
      'showroom_id': showroomId.toString(),
    };
  }
}

class TestDriveResponse {
  final int id;
  final String carId;
  final String showroomId;
  final String frontUserId;
  final String date;
  final String time;
  final String pickupAddress;
  final String pickupCity;
  final String pickupPincode;
  final String drivingLicense;
  final String aadharNo;
  final String note;
  final String status;
  final String createdAt;
  final String updatedAt;

  TestDriveResponse({
    required this.id,
    required this.carId,
    required this.showroomId,
    required this.frontUserId,
    required this.date,
    required this.time,
    required this.pickupAddress,
    required this.pickupCity,
    required this.pickupPincode,
    required this.drivingLicense,
    required this.aadharNo,
    required this.note,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TestDriveResponse.fromJson(Map<String, dynamic> json) {
    return TestDriveResponse(
      id: json['id'] as int,
      carId: json['car_id'] as String,
      showroomId: json['showroom_id'] as String,
      frontUserId: json['front_user_id'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      pickupAddress: json['pickup_address'] as String,
      pickupCity: json['pickup_city'] as String,
      pickupPincode: json['pickup_pincode'] as String,
      drivingLicense: json['driving_license'] as String,
      aadharNo: json['aadhar_no'] as String,
      note: json['note'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class TestDriveListResponse {
  final int id;
  final String createdAt;
  final String updatedAt;
  final int carId;
  final int frontUserId;
  final String date;
  final String time;
  final String pickupAddress;
  final String pickupCity;
  final String pickupPincode;
  final String drivingLicense;
  final String aadharNo;
  final String note;
  final String status;
  final String? showroomId;
  final TestDriveCar car;
  final Showroom showroom;
  final User frontUser;

  TestDriveListResponse({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.carId,
    required this.frontUserId,
    required this.date,
    required this.time,
    required this.pickupAddress,
    required this.pickupCity,
    required this.pickupPincode,
    required this.drivingLicense,
    required this.aadharNo,
    required this.note,
    required this.status,
    this.showroomId,
    required this.car,
    required this.showroom,
    required this.frontUser,
  });

  factory TestDriveListResponse.fromJson(Map<String, dynamic> json) {
    try {
      return TestDriveListResponse(
        id: json['id'] as int,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        carId: json['car_id'] as int,
        frontUserId: json['front_user_id'] as int,
        date: json['date'] as String,
        time: json['time'] as String,
        pickupAddress: json['pickup_address'] as String,
        pickupCity: json['pickup_city'] as String,
        pickupPincode: json['pickup_pincode'] as String,
        drivingLicense: json['driving_license'] as String,
        aadharNo: json['aadhar_no'] as String,
        note: json['note'] as String,
        status: json['status'] as String,
        showroomId: json['showroom_id']?.toString(),
        car: TestDriveCar.fromJson(json['car'] as Map<String, dynamic>),
        showroom: Showroom.fromJson(json['car']['showroom'] as Map<String, dynamic>),
        frontUser: User.fromJson(json['front_user'] as Map<String, dynamic>),
      );
    } catch (e) {
      print('Error parsing TestDriveListResponse: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
} 