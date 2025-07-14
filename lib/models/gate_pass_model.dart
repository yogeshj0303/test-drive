class GatePassResponse {
  final bool success;
  final String message;
  final List<GatePass> data;
  final List<dynamic> errors;

  GatePassResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
  });

  factory GatePassResponse.fromJson(Map<String, dynamic> json) {
    return GatePassResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => GatePass.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      errors: json['errors'] as List<dynamic>? ?? [],
    );
  }
}

class GatePass {
  final int id;
  final int textdriveId;
  final int employeeId;
  final String validDate;
  final String status;
  final String createdAt;
  final String updatedAt;
  final TestDriveDetails textdriveDetails;

  GatePass({
    required this.id,
    required this.textdriveId,
    required this.employeeId,
    required this.validDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.textdriveDetails,
  });

  factory GatePass.fromJson(Map<String, dynamic> json) {
    return GatePass(
      id: json['id'] ?? 0,
      textdriveId: json['textdrive_id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      validDate: json['valid_date'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      textdriveDetails: TestDriveDetails.fromJson(json['textdrive_details'] as Map<String, dynamic>),
    );
  }
}

class TestDriveDetails {
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
  final String showroomId;
  final String? rejectDescription;
  final int approvedEmployeeId;
  final String? cancelDescription;
  final String? cancelDateTime;
  final String driverId;
  final String driverUpdateDate;
  final int approverOrRejectBy;
  final String approvedOrRejectDate;
  final String? userName;
  final String? userMobile;
  final String? userEmail;
  final String? userAdhar;
  final String? rescheduledBy;
  final String? rescheduledDate;
  final Car car;
  final Employee requestbyEmplyee;
  final Employee approverRejecter;
  final Employee? rescheduler;
  final Employee approvedEmployee;

  TestDriveDetails({
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
    required this.showroomId,
    this.rejectDescription,
    required this.approvedEmployeeId,
    this.cancelDescription,
    this.cancelDateTime,
    required this.driverId,
    required this.driverUpdateDate,
    required this.approverOrRejectBy,
    required this.approvedOrRejectDate,
    this.userName,
    this.userMobile,
    this.userEmail,
    this.userAdhar,
    this.rescheduledBy,
    this.rescheduledDate,
    required this.car,
    required this.requestbyEmplyee,
    required this.approverRejecter,
    this.rescheduler,
    required this.approvedEmployee,
  });

  factory TestDriveDetails.fromJson(Map<String, dynamic> json) {
    return TestDriveDetails(
      id: json['id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      carId: json['car_id'] ?? 0,
      frontUserId: json['front_user_id'] ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      pickupCity: json['pickup_city'] ?? '',
      pickupPincode: json['pickup_pincode']?.toString() ?? '',
      drivingLicense: json['driving_license']?.toString() ?? '',
      aadharNo: json['aadhar_no']?.toString() ?? '',
      note: json['note'] ?? '',
      status: json['status'] ?? '',
      showroomId: json['showroom_id']?.toString() ?? '',
      rejectDescription: json['reject_description'],
      approvedEmployeeId: json['approved_employee_id'] ?? 0,
      cancelDescription: json['cancel_description'],
      cancelDateTime: json['cancel_date_time'],
      driverId: json['driver_id']?.toString() ?? '',
      driverUpdateDate: json['driver_update_date'] ?? '',
      approverOrRejectBy: json['approver_or_reject_by'] ?? 0,
      approvedOrRejectDate: json['approved_or_reject_date'] ?? '',
      userName: json['user_name'],
      userMobile: json['user_mobile'],
      userEmail: json['user_email'],
      userAdhar: json['user_adhar'],
      rescheduledBy: json['rescheduled_by']?.toString(),
      rescheduledDate: json['rescheduled_date']?.toString(),
      car: Car.fromJson(json['car'] as Map<String, dynamic>),
      requestbyEmplyee: Employee.fromJson(json['requestby_emplyee'] as Map<String, dynamic>),
      approverRejecter: Employee.fromJson(json['approver_rejecter'] as Map<String, dynamic>),
      rescheduler: json['rescheduler'] != null 
          ? Employee.fromJson(json['rescheduler'] as Map<String, dynamic>)
          : null,
      approvedEmployee: Employee.fromJson(json['approved_employee'] as Map<String, dynamic>),
    );
  }
}

class Car {
  final int id;
  final int ratting;
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
  final String drivetrain;
  final int seatingCapacity;
  final String? engineCapacity;
  final String? horsepower;
  final String? torque;
  final String bodyType;
  final String condition;
  final String? stockNumber;
  final String? registrationNumber;
  final String description;
  final String? features;
  final String? availabilityDate;
  final String? nextServiceDate;
  final String? createdBy;
  final String? updatedBy;
  final String createdAt;
  final String updatedAt;
  final Showroom showroom;

  Car({
    required this.id,
    required this.ratting,
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
    required this.drivetrain,
    required this.seatingCapacity,
    this.engineCapacity,
    this.horsepower,
    this.torque,
    required this.bodyType,
    required this.condition,
    this.stockNumber,
    this.registrationNumber,
    required this.description,
    this.features,
    this.availabilityDate,
    this.nextServiceDate,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.showroom,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] ?? 0,
      ratting: json['ratting'] ?? 0,
      name: json['name'] ?? '',
      modelNumber: json['model_number'] ?? '',
      showroomId: json['showroom_id'] ?? 0,
      status: json['status'] ?? '',
      mainImage: json['main_image'] ?? '',
      yearOfManufacture: json['year_of_manufacture'] ?? 0,
      color: json['color'] ?? '',
      vin: json['vin']?.toString(),
      fuelType: json['fuel_type'] ?? '',
      transmission: json['transmission'] ?? '',
      drivetrain: json['drivetrain'] ?? '',
      seatingCapacity: json['seating_capacity'] ?? 0,
      engineCapacity: json['engine_capacity']?.toString(),
      horsepower: json['horsepower']?.toString(),
      torque: json['torque']?.toString(),
      bodyType: json['body_type'] ?? '',
      condition: json['condition'] ?? '',
      stockNumber: json['stock_number']?.toString(),
      registrationNumber: json['registration_number']?.toString(),
      description: json['description'] ?? '',
      features: json['features']?.toString(),
      availabilityDate: json['availability_date']?.toString(),
      nextServiceDate: json['next_service_date']?.toString(),
      createdBy: json['created_by']?.toString(),
      updatedBy: json['updated_by']?.toString(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      showroom: Showroom.fromJson(json['showroom'] as Map<String, dynamic>),
    );
  }
}

class Showroom {
  final int id;
  final int authId;
  final String name;
  final String address;
  final String city;
  final String state;
  final String district;
  final String pincode;
  final String showroomImage;
  final int ratting;
  final String? passwordWord;
  final String createdAt;
  final String updatedAt;
  final String locationType;
  final String longitude;
  final String latitude;

  Showroom({
    required this.id,
    required this.authId,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.district,
    required this.pincode,
    required this.showroomImage,
    required this.ratting,
    this.passwordWord,
    required this.createdAt,
    required this.updatedAt,
    required this.locationType,
    required this.longitude,
    required this.latitude,
  });

  factory Showroom.fromJson(Map<String, dynamic> json) {
    return Showroom(
      id: json['id'] ?? 0,
      authId: json['auth_id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      pincode: json['pincode']?.toString() ?? '',
      showroomImage: json['showroom_image'] ?? '',
      ratting: json['ratting'] ?? 0,
      passwordWord: json['password_word']?.toString(),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      locationType: json['location_type'] ?? '',
      longitude: json['longitude']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
    );
  }
}

class Employee {
  final int id;
  final String name;
  final String email;
  final String? aadharNo;
  final String? drivingLicenseNo;
  final String? emailVerifiedAt;
  final String isAdmin;
  final String status;
  final int roleId;
  final int showroomId;
  final String mobileNo;
  final String avatar;
  final String createdAt;
  final String updatedAt;
  final String avatarUrl;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    this.aadharNo,
    this.drivingLicenseNo,
    this.emailVerifiedAt,
    required this.isAdmin,
    required this.status,
    required this.roleId,
    required this.showroomId,
    required this.mobileNo,
    required this.avatar,
    required this.createdAt,
    required this.updatedAt,
    required this.avatarUrl,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      aadharNo: json['aadhar_no']?.toString(),
      drivingLicenseNo: json['driving_license_no']?.toString(),
      emailVerifiedAt: json['email_verified_at']?.toString(),
      isAdmin: json['is_admin'] ?? '',
      status: json['status'] ?? '',
      roleId: json['role_id'] ?? 0,
      showroomId: json['showroom_id'] ?? 0,
      mobileNo: json['mobile_no']?.toString() ?? '',
      avatar: json['avatar'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
    );
  }
} 