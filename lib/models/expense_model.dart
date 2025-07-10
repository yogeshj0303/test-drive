import 'dart:io';

class ExpenseRequest {
  final int userId;
  final String description;
  final double amount;
  final String date;
  final String classification;
  final String paymentMode;
  final String? receiptNo;
  final String? note;
  final File? proofFile; // Photo or video file
  final String? proofFileType; // 'image' or 'video'

  ExpenseRequest({
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    required this.classification,
    required this.paymentMode,
    this.receiptNo,
    this.note,
    this.proofFile,
    this.proofFileType,
  });

  Map<String, String> toQueryParameters() {
    final params = <String, String>{
      'user_id': userId.toString(),
      'description': description,
      'amount': amount.toString(),
      'date': date,
      'classification': classification,
      'payment_mode': paymentMode,
    };

    if (receiptNo != null && receiptNo!.isNotEmpty) {
      params['receipt_no'] = receiptNo!;
    }

    if (note != null && note!.isNotEmpty) {
      params['note'] = note!;
    }

    return params;
  }

  // Method to get form data for file upload
  Map<String, dynamic> toFormData() {
    final formData = <String, dynamic>{
      'user_id': userId.toString(),
      'description': description,
      'amount': amount.toString(),
      'date': date,
      'classification': classification,
      'payment_mode': paymentMode,
    };

    if (receiptNo != null && receiptNo!.isNotEmpty) {
      formData['receipt_no'] = receiptNo!;
    }

    if (note != null && note!.isNotEmpty) {
      formData['note'] = note!;
    }

    // Add proof file if available
    if (proofFile != null) {
      formData['proof'] = proofFile!;
    }

    return formData;
  }
}

class ExpenseUser {
  final int id;
  final String name;
  final int showroomId;
  final String? avatarUrl;

  ExpenseUser({
    required this.id,
    required this.name,
    required this.showroomId,
    this.avatarUrl,
  });

  factory ExpenseUser.fromJson(Map<String, dynamic> json) {
    return ExpenseUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      showroomId: json['showroom_id'] as int? ?? 0,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ExpenseApprover {
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
  final String? avatar;
  final String createdAt;
  final String updatedAt;
  final String? avatarUrl;

  ExpenseApprover({
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
    this.avatar,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
  });

  factory ExpenseApprover.fromJson(Map<String, dynamic> json) {
    return ExpenseApprover(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      aadharNo: json['aadhar_no'] as String?,
      drivingLicenseNo: json['driving_license_no'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      isAdmin: json['is_admin'] as String? ?? '',
      status: json['status'] as String? ?? '',
      roleId: json['role_id'] as int? ?? 0,
      showroomId: json['showroom_id'] as int? ?? 0,
      mobileNo: json['mobile_no'] as String? ?? '',
      avatar: json['avatar'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class ExpenseResponse {
  final int id;
  final String description;
  final double amount;
  final String date;
  final String classification;
  final String paymentMode;
  final String status;
  final String? proof;
  final int userId;
  final int? approvedRejectBy;
  final String? approvedRejectDate;
  final String? rejectDescription;
  final String? proofUrl;
  final String? receiptNo;
  final String? note;
  final String? createdAt;
  final String? updatedAt;
  final ExpenseUser user;
  final ExpenseApprover? approver;

  ExpenseResponse({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.classification,
    required this.paymentMode,
    required this.status,
    this.proof,
    required this.userId,
    this.approvedRejectBy,
    this.approvedRejectDate,
    this.rejectDescription,
    this.proofUrl,
    this.receiptNo,
    this.note,
    this.createdAt,
    this.updatedAt,
    required this.user,
    this.approver,
  });

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseResponse(
      id: json['id'] as int,
      description: json['description'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date'] as String? ?? '',
      classification: json['classification'] as String? ?? '',
      paymentMode: json['payment_mode'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      proof: json['proof'] as String?,
      userId: json['user_id'] as int? ?? 0,
      approvedRejectBy: json['approved_reject_by'] != null 
          ? int.tryParse(json['approved_reject_by'].toString()) 
          : null,
      approvedRejectDate: json['approved_reject_date'] as String?,
      rejectDescription: json['reject_description'] as String?,
      proofUrl: json['proof_url'] as String?,
      receiptNo: json['receipt_no'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      user: json['user'] != null 
          ? ExpenseUser.fromJson(json['user'] as Map<String, dynamic>)
          : ExpenseUser(id: 0, name: '', showroomId: 0),
      approver: json['approver'] != null 
          ? ExpenseApprover.fromJson(json['approver'] as Map<String, dynamic>)
          : null,
    );
  }
} 