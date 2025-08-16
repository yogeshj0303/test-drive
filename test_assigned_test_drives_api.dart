import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'lib/models/test_drive_model.dart';

void main() {
  group('AssignedTestDrive API Integration Tests', () {
    test('should parse API response correctly', () {
      // Sample API response based on the provided data
      final apiResponse = {
        "success": true,
        "message": "Test drive records fetched successfully.",
        "data": [
          {
            "id": 50,
            "created_at": "2025-07-08T11:59:56.000000Z",
            "updated_at": "2025-07-10T08:35:23.000000Z",
            "car_id": 1,
            "front_user_id": 2,
            "date": "2025-06-21",
            "time": "10:32:00",
            "pickup_address": "ashoka bhopal",
            "pickup_city": "bhopal",
            "pickup_pincode": "462023",
            "driving_license": "1231231231212",
            "aadhar_no": "123412341234",
            "note": "sadsasad",
            "status": "rejected",
            "showroom_id": "1",
            "reject_description": null,
            "approved_employee_id": 3,
            "cancel_description": null,
            "cancel_date_time": null,
            "driver_id": null,
            "driver_update_date": "2025-07-10 08:35:23",
            "approver_or_reject_by": 2,
            "approved_or_reject_date": "2025-07-10 08:35:23",
            "user_name": "Aishwarya",
            "user_mobile": "9090909090",
            "user_email": "newuser@gmail.com",
            "user_adhar": "324232323",
            "rescheduled_by": null,
            "rescheduled_date": null,
            "car": {
              "id": 1,
              "ratting": 4,
              "name": "Tata Harrier EV",
              "model_number": "Tata Harrier EV",
              "showroom_id": 1,
              "status": "active",
              "main_image": "assets/car_images/main/1750409157_Er1fwNSB8l.webp",
              "year_of_manufacture": 2025,
              "color": "blue",
              "vin": null,
              "fuel_type": "electric",
              "transmission": "automatic",
              "drivetrain": null,
              "seating_capacity": 6,
              "engine_capacity": null,
              "horsepower": null,
              "torque": null,
              "body_type": null,
              "condition": "used",
              "stock_number": null,
              "registration_number": null,
              "description": null,
              "features": null,
              "availability_date": null,
              "next_service_date": null,
              "created_by": null,
              "updated_by": null,
              "created_at": "2025-06-20T08:45:57.000000Z",
              "updated_at": "2025-06-20T08:45:57.000000Z",
              "images": [
                {
                  "id": 2,
                  "car_id": 1,
                  "image_path": "assets/car_images/1/1750409157_anb8z4MduX.webp",
                  "created_at": "2025-06-20T08:45:57.000000Z",
                  "updated_at": "2025-06-20T08:45:57.000000Z"
                }
              ],
              "showroom": {
                "id": 1,
                "auth_id": 1,
                "name": "DriveEasy ashoka",
                "address": "bhopal",
                "city": "Bhopal",
                "state": "Madhya Pradesh",
                "district": "Bhopal",
                "pincode": "462023",
                "showroom_image": "assets/showroom/1751880748_686b942c3730f.jpg",
                "ratting": 4,
                "password_word": null,
                "created_at": "2025-06-17T08:39:34.000000Z",
                "updated_at": "2025-07-07T09:32:28.000000Z",
                "location_type": "showroom",
                "longitude": "23.2141799",
                "latitude": "77.4756307"
              }
            },
            "requestby_emplyee": {
              "id": 2,
              "name": "Aish",
              "email": "aish@gmail.com",
              "aadhar_no": null,
              "driving_license_no": null,
              "email_verified_at": null,
              "is_admin": "employee",
              "status": "active",
              "role_id": 2,
              "showroom_id": 1,
              "mobile_no": "9999999999",
              "avatar": "assets/profile/1750153119_6851379f63da2.jpg",
              "created_at": "2025-06-17T09:38:39.000000Z",
              "updated_at": "2025-07-11T05:28:29.000000Z",
              "avatar_url": "https://varenyam.acttconnect.com/assets/profile/1750153119_6851379f63da2.jpg"
            },
            "approver_rejecter": {
              "id": 2,
              "name": "Aish",
              "email": "aish@gmail.com",
              "aadhar_no": null,
              "driving_license_no": null,
              "email_verified_at": null,
              "is_admin": "employee",
              "status": "active",
              "role_id": 2,
              "showroom_id": 1,
              "mobile_no": "9999999999",
              "avatar": "assets/profile/1750153119_6851379f63da2.jpg",
              "created_at": "2025-06-17T09:38:39.000000Z",
              "updated_at": "2025-07-11T05:28:29.000000Z",
              "avatar_url": "https://varenyam.acttconnect.com/assets/profile/1750153119_6851379f63da2.jpg"
            },
            "rescheduler": null
          }
        ]
      };

      // Test parsing the response
      final response = AssignedTestDriveResponse.fromJson(apiResponse);
      
      // Verify the response structure
      expect(response.success, true);
      expect(response.message, "Test drive records fetched successfully.");
      expect(response.data.length, 1);
      
      // Verify the first test drive
      final testDrive = response.data.first;
      expect(testDrive.id, 50);
      expect(testDrive.userName, "Aishwarya");
      expect(testDrive.userMobile, "9090909090");
      expect(testDrive.status, "rejected");
      expect(testDrive.car?.name, "Tata Harrier EV");
      expect(testDrive.car?.showroom?.name, "DriveEasy ashoka");
      expect(testDrive.requestbyEmplyee?.name, "Aish");
      expect(testDrive.approverRejecter?.name, "Aish");
      expect(testDrive.rescheduler, null);
      
      print('✅ API response parsing test passed!');
    });

    test('should handle missing optional fields', () {
      final apiResponse = {
        "success": true,
        "message": "Test drive records fetched successfully.",
        "data": [
          {
            "id": 51,
            "car_id": 1,
            "front_user_id": 2,
            "status": "completed",
            "user_name": "Test User",
            "car": {
              "id": 1,
              "name": "Test Car",
              "showroom_id": 1,
              "year_of_manufacture": 2025,
              "seating_capacity": 5,
              "showroom": {
                "id": 1,
                "auth_id": 1,
                "name": "Test Showroom",
                "address": "Test Address",
                "city": "Test City",
                "state": "Test State",
                "district": "Test District",
                "pincode": "123456",
                "ratting": 4,
                "created_at": "2025-01-01T00:00:00.000000Z",
                "updated_at": "2025-01-01T00:00:00.000000Z"
              }
            }
          }
        ]
      };

      // Test parsing the response with minimal data
      final response = AssignedTestDriveResponse.fromJson(apiResponse);
      
      expect(response.success, true);
      expect(response.data.length, 1);
      
      final testDrive = response.data.first;
      expect(testDrive.id, 51);
      expect(testDrive.userName, "Test User");
      expect(testDrive.status, "completed");
      expect(testDrive.car?.name, "Test Car");
      expect(testDrive.car?.showroom?.name, "Test Showroom");
      
      print('✅ Missing optional fields test passed!');
    });
  });
} 