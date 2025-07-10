class User {
  final int id;
  final String name;
  final String email;
  final String? aadharNo;
  final String? drivingLicenseNo;
  final String? emailVerifiedAt;
  final String status;
  final int showroomId;
  final String mobileNo;
  final String? avatar;
  final String? avatarUrl;
  final List<Document>? documents;
  final Role? role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.aadharNo,
    this.drivingLicenseNo,
    this.emailVerifiedAt,
    required this.status,
    required this.showroomId,
    required this.mobileNo,
    this.avatar,
    this.avatarUrl,
    this.documents,
    this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      aadharNo: json['aadhar_no'] as String?,
      drivingLicenseNo: json['driving_license_no'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      status: json['status'] as String,
      showroomId: json['showroom_id'] as int,
      mobileNo: json['mobile_no'] as String,
      avatar: json['avatar'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      documents: json['documents'] != null 
          ? (json['documents'] as List<dynamic>)
              .map((doc) => Document.fromJson(doc as Map<String, dynamic>))
              .toList()
          : null,
      role: json['role'] != null 
          ? Role.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'aadhar_no': aadharNo,
      'driving_license_no': drivingLicenseNo,
      'email_verified_at': emailVerifiedAt,
      'status': status,
      'showroom_id': showroomId,
      'mobile_no': mobileNo,
      'avatar': avatar,
      'avatar_url': avatarUrl,
      'documents': documents?.map((doc) => doc.toJson()).toList(),
      'role': role?.toJson(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, status: $status, showroomId: $showroomId, mobileNo: $mobileNo, createdAt: $createdAt)';
  }
}

class Document {
  final int id;
  final int userId;
  final String documentName;
  final String filePath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String fileUrl;

  Document({
    required this.id,
    required this.userId,
    required this.documentName,
    required this.filePath,
    required this.createdAt,
    required this.updatedAt,
    required this.fileUrl,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
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
}

class Role {
  final int id;
  final String roleName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int showroomId;
  final Permissions permissions;

  Role({
    required this.id,
    required this.roleName,
    required this.createdAt,
    required this.updatedAt,
    required this.showroomId,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int,
      roleName: json['role_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      showroomId: json['showroom_id'] as int,
      permissions: Permissions.fromJson(json['permissions'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_name': roleName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'showroom_id': showroomId,
      'permissions': permissions.toJson(),
    };
  }
}

class Permissions {
  final int id;
  final int roleId;
  final int allTestDriveShow;
  final int viewTestDrive;
  final int statusChangeTestDrive;
  final int deleteTestDrive;
  final int approvedTestDrive;
  final int allExpenseShow;
  final int viewExpense;
  final int deleteExpense;
  final int statusChangeExpense;

  Permissions({
    required this.id,
    required this.roleId,
    required this.allTestDriveShow,
    required this.viewTestDrive,
    required this.statusChangeTestDrive,
    required this.deleteTestDrive,
    required this.approvedTestDrive,
    required this.allExpenseShow,
    required this.viewExpense,
    required this.deleteExpense,
    required this.statusChangeExpense,
  });

  // Helper methods to check permissions
  // 1 = not allowed, 2 = allowed
  bool get canShowAllTestDrives => allTestDriveShow == 2;
  bool get canViewTestDrive => viewTestDrive == 2;
  bool get canChangeTestDriveStatus => statusChangeTestDrive == 2;
  bool get canDeleteTestDrive => deleteTestDrive == 2;
  bool get canApproveTestDrive => approvedTestDrive == 2;
  bool get canShowAllExpenses => allExpenseShow == 2;
  bool get canViewExpense => viewExpense == 2;
  bool get canDeleteExpense => deleteExpense == 2;
  bool get canChangeExpenseStatus => statusChangeExpense == 2;

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      id: json['id'] as int,
      roleId: json['role_id'] as int,
      allTestDriveShow: json['all_test_drive_show'] as int,
      viewTestDrive: json['view_test_drive'] as int,
      statusChangeTestDrive: json['status_change_test_drive'] as int,
      deleteTestDrive: json['delete_test_drive'] as int,
      approvedTestDrive: json['approved_test_drive'] as int,
      allExpenseShow: json['all_expense_show'] as int,
      viewExpense: json['view_expense'] as int,
      deleteExpense: json['delete_expense'] as int,
      statusChangeExpense: json['status_change_expense'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_id': roleId,
      'all_test_drive_show': allTestDriveShow,
      'view_test_drive': viewTestDrive,
      'status_change_test_drive': statusChangeTestDrive,
      'delete_test_drive': deleteTestDrive,
      'approved_test_drive': approvedTestDrive,
      'all_expense_show': allExpenseShow,
      'view_expense': viewExpense,
      'delete_expense': deleteExpense,
      'status_change_expense': statusChangeExpense,
    };
  }
}

class LoginResponse {
  final String message;
  final String token;
  final User user;

  LoginResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] as String,
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
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



class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
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