class Employee {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String status;
  final int showroomId;
  final String mobileNo;
  final String? avatar;
  final String? avatarUrl;
  final List<EmployeeDocument> documents;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.status,
    required this.showroomId,
    required this.mobileNo,
    this.avatar,
    this.avatarUrl,
    required this.documents,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerifiedAt: json['email_verified_at'] as String?,
      status: json['status'] as String,
      showroomId: json['showroom_id'] as int,
      mobileNo: json['mobile_no'] as String,
      avatar: json['avatar'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((doc) => EmployeeDocument.fromJson(doc as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'status': status,
      'showroom_id': showroomId,
      'mobile_no': mobileNo,
      'avatar': avatar,
      'avatar_url': avatarUrl,
      'documents': documents.map((doc) => doc.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Employee(id: $id, name: $name, email: $email, status: $status, showroomId: $showroomId, mobileNo: $mobileNo)';
  }
}

class EmployeeDocument {
  final int id;
  final int userId;
  final String documentName;
  final String filePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fileUrl;

  EmployeeDocument({
    required this.id,
    required this.userId,
    required this.documentName,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    required this.fileUrl,
  });

  factory EmployeeDocument.fromJson(Map<String, dynamic> json) {
    return EmployeeDocument(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      documentName: json['document_name'] as String,
      filePath: json['file_path'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      fileUrl: json['file_url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_name': documentName,
      'file_path': filePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'file_url': fileUrl,
    };
  }

  @override
  String toString() {
    return 'EmployeeDocument(id: $id, documentName: $documentName, fileUrl: $fileUrl)';
  }
}

class EmployeeLoginResponse {
  final String message;
  final String token;
  final Employee user;

  EmployeeLoginResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory EmployeeLoginResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeLoginResponse(
      message: json['message'] as String,
      token: json['token'] as String,
      user: Employee.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'token': token,
      'user': user.toJson(),
    };
  }
}

class EmployeeLoginRequest {
  final String email;
  final String password;

  EmployeeLoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class EmployeeApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;

  EmployeeApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });

  factory EmployeeApiResponse.success(T data, {String message = 'Success'}) {
    return EmployeeApiResponse(
      success: true,
      message: message,
      data: data,
    );
  }

  factory EmployeeApiResponse.error(String message, {int? statusCode}) {
    return EmployeeApiResponse(
      success: false,
      message: message,
      statusCode: statusCode,
    );
  }
} 