import 'showroom_model.dart';

class TestDriveCar {
  final int id;
  final String? name;
  final String? modelNumber;
  final int showroomId;
  final String? status;
  final String? mainImage;
  final int yearOfManufacture;
  final String? color;
  final String? vin;
  final String? fuelType;
  final String? transmission;
  final String? drivetrain;
  final int seatingCapacity;
  final String? engineCapacity;
  final String? horsepower;
  final String? torque;
  final String? bodyType;
  final String? condition;
  final String? stockNumber;
  final String? registrationNumber;
  final String? description;
  final String? features;
  final String? availabilityDate;
  final String? nextServiceDate;
  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;
  final List<CarImage>? images;
  final Showroom? showroom;
  final int? ratting;

  TestDriveCar({
    required this.id,
    this.name,
    this.modelNumber,
    required this.showroomId,
    this.status,
    this.mainImage,
    required this.yearOfManufacture,
    this.color,
    this.vin,
    this.fuelType,
    this.transmission,
    this.drivetrain,
    required this.seatingCapacity,
    this.engineCapacity,
    this.horsepower,
    this.torque,
    this.bodyType,
    this.condition,
    this.stockNumber,
    this.registrationNumber,
    this.description,
    this.features,
    this.availabilityDate,
    this.nextServiceDate,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.images,
    this.showroom,
    this.ratting,
  });

  factory TestDriveCar.fromJson(Map<String, dynamic> json) {
    try {
      final showroomJson = json['showroom'] as Map<String, dynamic>?;
      
      return TestDriveCar(
        id: json['id'] as int? ?? 0,
        name: json['name'] as String?,
        modelNumber: json['model_number'] as String?,
        showroomId: json['showroom_id'] as int? ?? 0,
        status: json['status'] as String?,
        mainImage: json['main_image'] as String?,
        yearOfManufacture: json['year_of_manufacture'] as int? ?? 0,
        color: json['color'] as String?,
        vin: json['vin'] as String?,
        fuelType: json['fuel_type'] as String?,
        transmission: json['transmission'] as String?,
        drivetrain: json['drivetrain'] as String?,
        seatingCapacity: json['seating_capacity'] as int? ?? 0,
        engineCapacity: json['engine_capacity']?.toString(),
        horsepower: json['horsepower']?.toString(),
        torque: json['torque']?.toString(),
        bodyType: json['body_type'] as String?,
        condition: json['condition'] as String?,
        stockNumber: json['stock_number']?.toString(),
        registrationNumber: json['registration_number']?.toString(),
        description: json['description'] as String?,
        features: json['features'] as String?,
        availabilityDate: json['availability_date'] as String?,
        nextServiceDate: json['next_service_date'] as String?,
        createdBy: json['created_by']?.toString(),
        updatedBy: json['updated_by']?.toString(),
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        images: (json['images'] as List<dynamic>?)
                ?.map((imageJson) => CarImage.fromJson(imageJson as Map<String, dynamic>))
                .toList(),
        showroom: showroomJson != null ? Showroom.fromJson(showroomJson) : null,
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
  final String? imagePath;
  final String? createdAt;
  final String? updatedAt;

  CarImage({
    required this.id,
    required this.carId,
    this.imagePath,
    this.createdAt,
    this.updatedAt,
  });

  factory CarImage.fromJson(Map<String, dynamic> json) {
    try {
      return CarImage(
        id: json['id'] as int? ?? 0,
        carId: json['car_id'] as int? ?? 0,
        imagePath: json['image_path'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
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
  final String? createdAt;
  final String? updatedAt;
  final int carId;
  final int frontUserId;
  final String? date;
  final String? time;
  final String? pickupAddress;
  final String? pickupCity;
  final String? pickupPincode;
  final String? drivingLicense;
  final String? aadharNo;
  final String? note;
  final String? status;
  final String? showroomId;
  final String? rejectDescription;
  final String? approvedEmployeeId;
  final String? cancelDescription;
  final String? cancelDateTime;
  final TestDriveCar? car;
  final Showroom? showroom;
  final TestDriveUser? frontUser;

  TestDriveListResponse({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.carId,
    required this.frontUserId,
    this.date,
    this.time,
    this.pickupAddress,
    this.pickupCity,
    this.pickupPincode,
    this.drivingLicense,
    this.aadharNo,
    this.note,
    this.status,
    this.showroomId,
    this.rejectDescription,
    this.approvedEmployeeId,
    this.cancelDescription,
    this.cancelDateTime,
    this.car,
    this.showroom,
    this.frontUser,
  });

  factory TestDriveListResponse.fromJson(Map<String, dynamic> json) {
    try {
      final carJson = json['car'] as Map<String, dynamic>?;
      final frontUserJson = json['front_user'] as Map<String, dynamic>?;
      final showroomJson = carJson?['showroom'] as Map<String, dynamic>?;
      
      return TestDriveListResponse(
        id: json['id'] as int? ?? 0,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
        carId: json['car_id'] as int? ?? 0,
        frontUserId: json['front_user_id'] as int? ?? 0,
        date: json['date'] as String?,
        time: json['time'] as String?,
        pickupAddress: json['pickup_address'] as String?,
        pickupCity: json['pickup_city'] as String?,
        pickupPincode: json['pickup_pincode'] as String?,
        drivingLicense: json['driving_license'] as String?,
        aadharNo: json['aadhar_no'] as String?,
        note: json['note'] as String?,
        status: json['status'] as String?,
        showroomId: json['showroom_id']?.toString(),
        rejectDescription: json['reject_description'] as String?,
        approvedEmployeeId: json['approved_employee_id']?.toString(),
        cancelDescription: json['cancel_description'] as String?,
        cancelDateTime: json['cancel_date_time'] as String?,
        car: carJson != null ? TestDriveCar.fromJson(carJson) : null,
        showroom: showroomJson != null ? Showroom.fromJson(showroomJson) : null,
        frontUser: frontUserJson != null ? TestDriveUser.fromJson(frontUserJson) : null,
      );
    } catch (e) {
      print('Error parsing TestDriveListResponse: $e');
      print('JSON data: $json');
      rethrow;
    }
  }
}

class AssignedTestDriveResponse {
  final bool success;
  final String message;
  final List<AssignedTestDrive> data;

  AssignedTestDriveResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AssignedTestDriveResponse.fromJson(Map<String, dynamic> json) {
    return AssignedTestDriveResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => AssignedTestDrive.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AssignedTestDrive {
  final int id;
  final String? createdAt;
  final String? updatedAt;
  final int carId;
  final int frontUserId;
  final String? date;
  final String? time;
  final String? pickupAddress;
  final String? pickupCity;
  final String? pickupPincode;
  final String? drivingLicense;
  final String? aadharNo;
  final String? note;
  final String? status;
  final String? showroomId;
  final String? rejectDescription;
  final int? approvedEmployeeId;
  final String? cancelDescription;
  final String? cancelDateTime;
  final String? driverId;
  final String? driverUpdateDate;
  final String? approverOrRejectBy;
  final String? approvedOrRejectDate;
  final String? userName;
  final String? userMobile;
  final String? userEmail;
  final String? userAdhar;
  final TestDriveCar? car;
  final TestDriveUser? frontUser;
  final TestDriveUser? requestbyEmplyee;

  AssignedTestDrive({
    required this.id,
    this.createdAt,
    this.updatedAt,
    required this.carId,
    required this.frontUserId,
    this.date,
    this.time,
    this.pickupAddress,
    this.pickupCity,
    this.pickupPincode,
    this.drivingLicense,
    this.aadharNo,
    this.note,
    this.status,
    this.showroomId,
    this.rejectDescription,
    this.approvedEmployeeId,
    this.cancelDescription,
    this.cancelDateTime,
    this.driverId,
    this.driverUpdateDate,
    this.approverOrRejectBy,
    this.approvedOrRejectDate,
    this.userName,
    this.userMobile,
    this.userEmail,
    this.userAdhar,
    this.car,
    this.frontUser,
    this.requestbyEmplyee,
  });

  factory AssignedTestDrive.fromJson(Map<String, dynamic> json) {
    final carJson = json['car'] as Map<String, dynamic>?;
    final frontUserJson = json['front_user'] as Map<String, dynamic>?;
    final requestbyEmplyeeJson = json['requestby_emplyee'] as Map<String, dynamic>?;
    
    return AssignedTestDrive(
      id: json['id'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      carId: json['car_id'] as int? ?? 0,
      frontUserId: json['front_user_id'] as int? ?? 0,
      date: json['date'] as String?,
      time: json['time'] as String?,
      pickupAddress: json['pickup_address'] as String?,
      pickupCity: json['pickup_city'] as String?,
      pickupPincode: json['pickup_pincode'] as String?,
      drivingLicense: json['driving_license'] as String?,
      aadharNo: json['aadhar_no'] as String?,
      note: json['note'] as String?,
      status: json['status'] as String?,
      showroomId: json['showroom_id']?.toString(),
      rejectDescription: json['reject_description'] as String?,
      approvedEmployeeId: json['approved_employee_id'] as int?,
      cancelDescription: json['cancel_description'] as String?,
      cancelDateTime: json['cancel_date_time'] as String?,
      driverId: json['driver_id']?.toString(),
      driverUpdateDate: json['driver_update_date'] as String?,
      approverOrRejectBy: json['approver_or_reject_by']?.toString(),
      approvedOrRejectDate: json['approved_or_reject_date'] as String?,
      userName: json['user_name'] as String?,
      userMobile: json['user_mobile'] as String?,
      userEmail: json['user_email'] as String?,
      userAdhar: json['user_adhar'] as String?,
      car: carJson != null ? TestDriveCar.fromJson(carJson) : null,
      frontUser: frontUserJson != null ? TestDriveUser.fromJson(frontUserJson) : null,
      requestbyEmplyee: requestbyEmplyeeJson != null ? TestDriveUser.fromJson(requestbyEmplyeeJson) : null,
    );
  }
}

class TestDriveUser {
  final int id;
  final String? name;
  final String? email;
  final String? mobile;
  final String? createdAt;
  final String? updatedAt;
  final String? city;
  final String? state;
  final String? district;
  final String? pincode;

  TestDriveUser({
    required this.id,
    this.name,
    this.email,
    this.mobile,
    this.createdAt,
    this.updatedAt,
    this.city,
    this.state,
    this.district,
    this.pincode,
  });

  factory TestDriveUser.fromJson(Map<String, dynamic> json) {
    return TestDriveUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      district: json['district'] as String?,
      pincode: json['pincode'] as String?,
    );
  }
} 