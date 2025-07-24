import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee_model.dart';
import '../models/test_drive_model.dart';

class EmployeeStorageService {
  static const String _employeeKey = 'employee_data';
  static const String _employeeTokenKey = 'employee_token';
  static const String _isEmployeeLoggedInKey = 'is_employee_logged_in';

  // Save employee data
  static Future<void> saveEmployeeData(EmployeeLoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save employee data
    await prefs.setString(_employeeKey, jsonEncode(loginResponse.user.toJson()));
    
    // Save token
    await prefs.setString(_employeeTokenKey, loginResponse.token);
    
    // Set login status
    await prefs.setBool(_isEmployeeLoggedInKey, true);
  }

  // Get employee data
  static Future<Employee?> getEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeJson = prefs.getString(_employeeKey);
    
    if (employeeJson != null) {
      try {
        final employeeData = jsonDecode(employeeJson) as Map<String, dynamic>;
        return Employee.fromJson(employeeData);
      } catch (e) {
        print('Error parsing employee data: $e');
        return null;
      }
    }
    return null;
  }

  // Get employee token
  static Future<String?> getEmployeeToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeTokenKey);
  }

  // Check if employee is logged in
  static Future<bool> isEmployeeLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isEmployeeLoggedInKey) ?? false;
  }

  // Check if employee data exists
  static Future<bool> hasEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeJson = prefs.getString(_employeeKey);
    return employeeJson != null;
  }

  // Check if employee has a valid authentication session
  static Future<bool> hasValidSession() async {
    try {
      final isLoggedIn = await isEmployeeLoggedIn();
      final hasData = await hasEmployeeData();
      
      // Check if employee is logged in and has data
      return isLoggedIn && hasData;
    } catch (e) {
      return false;
    }
  }

  // Clear employee data (logout)
  static Future<void> clearEmployeeData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_employeeKey);
    await prefs.remove(_employeeTokenKey);
    await prefs.setBool(_isEmployeeLoggedInKey, false);
  }

  // Update employee data
  static Future<void> updateEmployeeData(Employee employee) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_employeeKey, jsonEncode(employee.toJson()));
  }

  // --- Test Drive Location Tracking ---

  static String _locationKey(int testDriveId) => 'test_drive_location_testDriveId';

  // Save or update a location point for a test drive
  static Future<void> addLocationPoint(int testDriveId, LocationPoint point) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _locationKey(testDriveId);
    final jsonString = prefs.getString(key);
    TestDriveLocationHistory history;
    if (jsonString != null) {
      history = TestDriveLocationHistory.fromJson(jsonDecode(jsonString));
      history = TestDriveLocationHistory(
        testDriveId: testDriveId,
        points: [...history.points, point],
        isCompleted: history.isCompleted,
      );
    } else {
      history = TestDriveLocationHistory(testDriveId: testDriveId, points: [point]);
    }
    await prefs.setString(key, jsonEncode(history.toJson()));
  }

  // Get location history for a test drive
  static Future<TestDriveLocationHistory?> getLocationHistory(int testDriveId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _locationKey(testDriveId);
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      return TestDriveLocationHistory.fromJson(jsonDecode(jsonString));
    }
    return null;
  }

  // Mark a test drive as completed (stops tracking)
  static Future<void> completeTestDriveLocation(int testDriveId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _locationKey(testDriveId);
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      final history = TestDriveLocationHistory.fromJson(jsonDecode(jsonString));
      final updated = TestDriveLocationHistory(
        testDriveId: testDriveId,
        points: history.points,
        isCompleted: true,
      );
      await prefs.setString(key, jsonEncode(updated.toJson()));
    }
  }

  // Get all test drive location histories (optionally filter by completed/incomplete)
  static Future<List<TestDriveLocationHistory>> getAllTestDriveLocationHistories({bool? completed}) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('test_drive_location_'));
    final List<TestDriveLocationHistory> histories = [];
    for (final key in keys) {
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final history = TestDriveLocationHistory.fromJson(jsonDecode(jsonString));
        if (completed == null || history.isCompleted == completed) {
          histories.add(history);
        }
      }
    }
    return histories;
  }
} 