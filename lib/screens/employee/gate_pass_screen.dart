import 'package:flutter/material.dart';
import '../../models/test_drive_model.dart';

class EmployeeGatePassScreen extends StatefulWidget {
  final AssignedTestDrive testDrive;
  const EmployeeGatePassScreen({super.key, required this.testDrive});

  @override
  State<EmployeeGatePassScreen> createState() => _EmployeeGatePassScreenState();
}

class _EmployeeGatePassScreenState extends State<EmployeeGatePassScreen> {
  final TextEditingController _timeOutController = TextEditingController();
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _securityInchargeController = TextEditingController();
  final TextEditingController _executiveNameController = TextEditingController();
  final TextEditingController _openingKmController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    _timeOutController.dispose();
    _driverNameController.dispose();
    _securityInchargeController.dispose();
    _executiveNameController.dispose();
    _openingKmController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gate Pass',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3080A5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF3080A5)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: const [
                        Text('VARENYAM MOTORCAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        SizedBox(height: 4),
                        Text('DEMO VEHICLE GATE PASS', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('TEST DRIVE OFFICIAL USE', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const Divider(),
                  _buildDetailRow('Sr. No.', 'TD-${widget.testDrive.id.toString().padLeft(6, '0')}'),
                  _buildDetailRow('Customer Name', widget.testDrive.frontUser?.name ?? ''),
                  _buildEditableRow('Address', _addressController),
                  _buildDetailRow('Vehicle No./Chassis No.',
                    [
                      widget.testDrive.car?.registrationNumber,
                      widget.testDrive.car?.vin
                    ].where((e) => e != null && e.isNotEmpty).join(' / ')
                  ),
                  _buildDetailRow('Contact No.', widget.testDrive.frontUser?.mobile ?? ''),
                  _buildEditableRow('Time out', _timeOutController),
                  _buildEditableRow("Driver's Name", _driverNameController),
                  _buildEditableRow('Security Incharge', _securityInchargeController),
                  _buildEditableRow('Executive Name', _executiveNameController),
                  _buildEditableRow('Opening KM', _openingKmController),
                  _buildDetailRow('Date', widget.testDrive.date ?? ''),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 