import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/employee_storage_service.dart';
import '../../services/api_service.dart';
import '../../models/employee_model.dart';
import '../../models/showroom_model.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _positionController = TextEditingController();
  
  Employee? _employee;
  Showroom? _showroom;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
  }

  Future<void> _loadEmployeeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final employee = await EmployeeStorageService.getEmployeeData();
      if (employee != null) {
        setState(() {
          _employee = employee;
          _populateControllers();
        });
        
        // Load showroom data
        await _loadShowroomData(employee.showroomId);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadShowroomData(int showroomId) async {
    try {
      final apiService = ApiService();
      final response = await apiService.getShowroomById(showroomId);
      
      if (response.success && response.data != null) {
        setState(() {
          _showroom = response.data;
          _updateAddressField();
        });
      }
    } catch (e) {
      // If showroom data fails to load, we'll use a fallback
      print('Error loading showroom data: $e');
    }
  }

  void _populateControllers() {
    if (_employee != null) {
      _nameController.text = _employee!.name;
      _emailController.text = _employee!.email;
      _phoneController.text = _employee!.mobileNo;
      _addressController.text = 'Loading address...'; // Will be updated when showroom loads
      _employeeIdController.text = 'EMP${_employee!.id.toString().padLeft(3, '0')}';
      _departmentController.text = 'Test Drive';
      _positionController.text = 'Test Drive Specialist';
    }
  }

  void _updateAddressField() {
    if (_showroom != null) {
      _addressController.text = _showroom!.fullAddress;
    } else {
      _addressController.text = 'Address not available';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Loading profile...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            : _employee == null
                ? Center(
                    child: Text(
                      'No employee data available',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompactProfileSection(theme),
                        const SizedBox(height: 20),
                        _buildCompactForm(theme),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCompactProfileSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: _employee?.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    _employee!.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 25,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.person_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 25,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 25,
                ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _employee?.name ?? 'Employee Name',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Test Drive Specialist • ${_showroom?.name ?? 'Loading...'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactForm(ThemeData theme) {
    return Column(
      children: [
        _buildSectionHeader(theme, 'Personal Details'),
        const SizedBox(height: 8),
        _buildCompactTextField(
          controller: _nameController,
          label: 'Full Name',
          icon: Icons.person_outline_rounded,
          enabled: false,
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_outlined,
          enabled: false,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          enabled: false,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on_outlined,
          enabled: false,
          maxLines: 1,
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(theme, 'Work Information'),
        const SizedBox(height: 8),
        _buildCompactTextField(
          controller: _employeeIdController,
          label: 'Employee ID',
          icon: Icons.badge_outlined,
          enabled: false,
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _departmentController,
          label: 'Department',
          icon: Icons.business_outlined,
          enabled: false,
        ),
        const SizedBox(height: 12),
        _buildCompactTextField(
          controller: _positionController,
          label: 'Position',
          icon: Icons.work_outline_rounded,
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(
              icon,
              color: enabled ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 18,
            ),
          ),
        ),
      ],
    );
  }
} 