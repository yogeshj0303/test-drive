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

class ExpenseResponse {
  final int id;
  final int userId;
  final String description;
  final double amount;
  final String date;
  final String classification;
  final String paymentMode;
  final String? receiptNo;
  final String? note;
  final String createdAt;
  final String updatedAt;

  ExpenseResponse({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.date,
    required this.classification,
    required this.paymentMode,
    this.receiptNo,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseResponse.fromJson(Map<String, dynamic> json) {
    return ExpenseResponse(
      id: json['id'] as int,
      userId: int.parse(json['user_id'] as String),
      description: json['description'] as String,
      amount: double.parse(json['amount'] as String),
      date: json['date'] as String,
      classification: json['classification'] as String,
      paymentMode: json['payment_mode'] as String,
      receiptNo: json['receipt_no'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
} 