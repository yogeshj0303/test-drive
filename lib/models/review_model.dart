class ReviewRequest {
  final int userId;
  final int testDriveId;
  final String overallExperience;
  final String comfortInterior;
  final String performanceHandling;
  final String valueMoney;
  final bool recommend;
  final String comment;

  ReviewRequest({
    required this.userId,
    required this.testDriveId,
    required this.overallExperience,
    required this.comfortInterior,
    required this.performanceHandling,
    required this.valueMoney,
    required this.recommend,
    required this.comment,
  });

  Map<String, String> toQueryParameters() {
    return {
      'user_id': userId.toString(),
      'testdrive_id': testDriveId.toString(),
      'overall_experience': overallExperience,
      'comfort_interior': comfortInterior,
      'performance_handling': performanceHandling,
      'value_money': valueMoney,
      'recommend': recommend ? 'yes' : 'no',
      'comment': comment,
    };
  }
}

class ReviewResponse {
  final int id;
  final int userId;
  final int testDriveId;
  final String overallExperience;
  final String comfortInterior;
  final String performanceHandling;
  final String valueMoney;
  final bool recommend;
  final String comment;
  final String createdAt;
  final String updatedAt;
  final User user;
  final TestDrive testDrive;

  ReviewResponse({
    required this.id,
    required this.userId,
    required this.testDriveId,
    required this.overallExperience,
    required this.comfortInterior,
    required this.performanceHandling,
    required this.valueMoney,
    required this.recommend,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.testDrive,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      id: json['id'] as int,
      userId: int.parse(json['user_id'] as String),
      testDriveId: int.parse(json['testdrive_id'] as String),
      overallExperience: json['overall_experience'] as String,
      comfortInterior: json['comfort_interior'] as String,
      performanceHandling: json['performance_handling'] as String,
      valueMoney: json['value_money'] as String,
      recommend: json['recommend'] as bool,
      comment: json['comment'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      testDrive: TestDrive.fromJson(json['testdrive'] as Map<String, dynamic>),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String createdAt;
  final String updatedAt;
  final String city;
  final String state;
  final String district;
  final String pincode;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.createdAt,
    required this.updatedAt,
    required this.city,
    required this.state,
    required this.district,
    required this.pincode,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      district: json['district'] as String,
      pincode: json['pincode'] as String,
    );
  }
}

class TestDrive {
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
  final int? showroomId;
  final String? rejectDescription;
  final int? approvedEmployeeId;
  final String? cancelDescription;
  final String? cancelDateTime;

  TestDrive({
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
    this.rejectDescription,
    this.approvedEmployeeId,
    this.cancelDescription,
    this.cancelDateTime,
  });

  factory TestDrive.fromJson(Map<String, dynamic> json) {
    return TestDrive(
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
      showroomId: json['showroom_id'] != null ? int.tryParse(json['showroom_id'].toString()) : null,
      rejectDescription: json['reject_description'] as String?,
      approvedEmployeeId: json['approved_employee_id'] as int?,
      cancelDescription: json['cancel_description'] as String?,
      cancelDateTime: json['cancel_date_time'] as String?,
    );
  }
} 