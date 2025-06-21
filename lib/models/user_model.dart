class User {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String city;
  final String state;
  final String district;
  final String pincode;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.city,
    required this.state,
    required this.district,
    required this.pincode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      mobile: json['mobile'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      district: json['district'] as String,
      pincode: json['pincode'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'city': city,
      'state': state,
      'district': district,
      'pincode': pincode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, mobile: $mobile, city: $city, state: $state, district: $district, pincode: $pincode)';
  }
}

class LoginResponse {
  final String message;
  final int userId;
  final User user;

  LoginResponse({
    required this.message,
    required this.userId,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String,
      userId: json['user_id'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'user_id': userId,
      'user': user.toJson(),
    };
  }
}

class SignupRequest {
  final String name;
  final String email;
  final String password;
  final String mobile;
  final String city;
  final String state;
  final String district;
  final String pincode;

  SignupRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.mobile,
    required this.city,
    required this.state,
    required this.district,
    required this.pincode,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'mobile': mobile,
      'city': city,
      'state': state,
      'district': district,
      'pincode': pincode,
    };
  }
}

class LoginRequest {
  final String emailOrMobile;
  final String password;

  LoginRequest({
    required this.emailOrMobile,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email_or_mobile': emailOrMobile,
      'password': password,
    };
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory ApiResponse.success(T data, {String message = 'Success'}) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
} 