import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _dobController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _pincodeController;

  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();
  
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _dobController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _districtController = TextEditingController();
    _pincodeController = TextEditingController();
    
    // Add listeners to update location field
    _cityController.addListener(_updateLocationField);
    _stateController.addListener(_updateLocationField);
    
    _loadUserProfile();
  }

  void _updateLocationField() {
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    if (city.isNotEmpty && state.isNotEmpty) {
      _locationController.text = '$city, $state';
    } else if (city.isNotEmpty) {
      _locationController.text = city;
    } else if (state.isNotEmpty) {
      _locationController.text = state;
    } else {
      _locationController.text = '';
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final currentUser = await _storageService.getUser();
      if (currentUser != null) {
        final response = await _apiService.getUserProfile(currentUser.id);
        if (response.success && response.data != null) {
          setState(() {
            _user = response.data;
            _isLoading = false;
          });
          _populateControllers();
        } else {
          setState(() {
            _errorMessage = response.message;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'No user data found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _populateControllers() {
    if (_user != null) {
      _nameController.text = _user!.name;
      _emailController.text = _user!.email;
      _phoneController.text = _user!.mobileNo;
      _locationController.text = 'Not specified'; // API doesn't provide city/state
      _dobController.text = 'Not specified'; // API doesn't provide DOB
      _cityController.text = 'Not specified'; // API doesn't provide city
      _stateController.text = 'Not specified'; // API doesn't provide state
      _districtController.text = 'Not specified'; // API doesn't provide district
      _pincodeController.text = 'Not specified'; // API doesn't provide pincode
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Loading profile...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Personal Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios, size: 16),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Error Loading Profile',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingL),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadUserProfile();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Personal Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Basic Information'),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildSectionHeader(context, 'Location Information'),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city_outlined,
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _stateController,
                  label: 'State',
                  icon: Icons.map_outlined,
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _districtController,
                  label: 'District',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _pincodeController,
                  label: 'Pincode',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildSectionHeader(context, 'Additional Information'),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _locationController,
                  label: 'Location (City, State)',
                  icon: Icons.location_on_outlined,
                  readOnly: true,
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildTextField(
                  context,
                  controller: _dobController,
                  label: 'Date of Birth',
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: AppTheme.spacingM),
                _buildSectionHeader(context, 'Account Information'),
                const SizedBox(height: AppTheme.spacingS),
                _buildInfoCard(
                  context,
                  'Member Since',
                  _formatMemberSinceDate(),
                  Icons.calendar_month_outlined,
                ),
                const SizedBox(height: AppTheme.spacingS),
                _buildInfoCard(
                  context,
                  'Account Status',
                  'Active',
                  Icons.verified_outlined,
                  statusColor: AppTheme.successColor,
                ),
              ],
            ),
          ),
        ),
      );
  }

  String _formatMemberSinceDate() {
    if (_user?.createdAt == null) {
      return 'Not available';
    }
    
    try {
      final date = _user!.createdAt!;
      
      // Format as "DD/MM/YYYY"
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      
      return '$day/$month/$year';
    } catch (e) {
      return 'Not available';
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = true, // Changed to true to make all fields read-only
    VoidCallback? onTap,
    bool obscureText = false,
  }) {
    final theme = Theme.of(context);
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      style: theme.textTheme.bodyMedium?.copyWith(
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        isDense: true,
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (statusColor ?? theme.colorScheme.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: statusColor ?? theme.colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor ?? theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }


} 