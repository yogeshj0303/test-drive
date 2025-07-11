
class ActivityLogResponse {
  final bool success;
  final String message;
  final List<ActivityLog> data;

  ActivityLogResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ActivityLogResponse.fromJson(Map<String, dynamic> json) {
    return ActivityLogResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)?.map((e) => ActivityLog.fromJson(e)).toList() ?? [],
    );
  }
}

class ActivityLog {
  final int id;
  final String tableName;
  final String userType;
  final int userId;
  final int tableId;
  final String operation;
  final String operationDescription;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userName;
  final Map<String, dynamic>? tableData;

  ActivityLog({
    required this.id,
    required this.tableName,
    required this.userType,
    required this.userId,
    required this.tableId,
    required this.operation,
    required this.operationDescription,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
    this.tableData,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    try {
      return ActivityLog(
        id: json['id'] ?? 0,
        tableName: json['table_name'] ?? '',
        userType: json['user_type'] ?? '',
        userId: json['user_id'] ?? 0,
        tableId: json['table_id'] ?? 0,
        operation: json['operation'] ?? '',
        operationDescription: json['operation_description'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
        userName: json['user_name'] ?? '',
        tableData: json['table_data'] as Map<String, dynamic>?, // Explicitly cast to Map<String, dynamic>?
      );
    } catch (e) {
      // Return a default activity log if parsing fails
      return ActivityLog(
        id: json['id'] ?? 0,
        tableName: json['table_name'] ?? '',
        userType: json['user_type'] ?? '',
        userId: json['user_id'] ?? 0,
        tableId: json['table_id'] ?? 0,
        operation: json['operation'] ?? 'Unknown Operation',
        operationDescription: json['operation_description'] ?? 'Unable to parse activity description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userName: json['user_name'] ?? 'Unknown User',
        tableData: null,
      );
    }
  }
} 