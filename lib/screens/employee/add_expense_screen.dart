import 'package:flutter/material.dart';
import 'dart:io';   
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../services/driver_api_service.dart';
import '../../services/employee_storage_service.dart';
import '../../models/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AddExpenseScreen extends StatefulWidget {
  final bool showBackButton;
  
  const AddExpenseScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: "en_IN", symbol: "₹");
  final _receiptNumberController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Fuel';
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  // File upload related variables
  File? _selectedImage;
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  final List<String> _categories = [
    'Fuel',
    'Meals',
    'Transportation',
    'Parking',
    'Tolls',
    'Maintenance',
    'Office Supplies',
    'Other',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Company Card',
    'Reimbursement',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_formatAmountInput);
  }

  void _formatAmountInput() {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (text.isEmpty) return;
    final double? value = double.tryParse(text);
    if (value == null) return;
    final newText = value.truncateToDouble() == value
        ? _currencyFormat.format(value).replaceAll('.00', '')
        : _currencyFormat.format(value);
    if (_amountController.text != newText) {
      final selectionIndex = newText.length;
      _amountController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.removeListener(_formatAmountInput);
    _amountController.dispose();
    _receiptNumberController.dispose();
    _notesController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    
    // Show source selection dialog
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return;
    
    final XFile? image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _selectedVideo = null; // Clear video if image is selected
        _videoController?.dispose();
        _videoController = null;
        _isVideoInitialized = false;
      });
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    
    // Show source selection dialog
    final ImageSource? source = await _showVideoSourceDialog();
    if (source == null) return;
    
    final XFile? video = await picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5), // Limit to 5 minutes
    );
    
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _selectedImage = null; // Clear image if video is selected
        _isVideoInitialized = false;
      });
      
      // Initialize video controller
      _videoController = VideoPlayerController.file(_selectedVideo!);
      await _videoController!.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Select Image Source',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3080A5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF3080A5),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3080A5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF3080A5),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<ImageSource?> _showVideoSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Select Video Source',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3080A5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Color(0xFF3080A5),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Record a new video'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3080A5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.video_library,
                    color: Color(0xFF3080A5),
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  void _removeMedia() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3080A5),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Validate file size if a file is selected
        if (_selectedImage != null) {
          final fileSize = await _selectedImage!.length();
          final maxSize = 10 * 1024 * 1024; // 10MB limit for images
          if (fileSize > maxSize) {
            throw Exception('Image file size must be less than 10MB');
          }
        }
        
        if (_selectedVideo != null) {
          final fileSize = await _selectedVideo!.length();
          final maxSize = 50 * 1024 * 1024; // 50MB limit for videos
          if (fileSize > maxSize) {
            throw Exception('Video file size must be less than 50MB');
          }
        }

        // Get current employee data
        final employee = await EmployeeStorageService.getEmployeeData();
        if (employee == null) {
          throw Exception('Employee data not found. Please login again.');
        }

        // Format date to YYYY-MM-DD
        final formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

        // Create expense request
        final expenseRequest = ExpenseRequest(
          userId: employee.id,
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text.trim().replaceAll('₹', '').replaceAll(',', '')),
          date: formattedDate,
          classification: _selectedCategory,
          paymentMode: _selectedPaymentMethod,
          receiptNo: _receiptNumberController.text.trim().isNotEmpty 
              ? _receiptNumberController.text.trim() 
              : null,
          note: _notesController.text.trim().isNotEmpty 
              ? _notesController.text.trim() 
              : null,
          proofFile: _selectedImage ?? _selectedVideo,
          proofFileType: _selectedImage != null ? 'image' : _selectedVideo != null ? 'video' : null,
        );

        // Debug: Show what's being sent
        debugPrint('Submitting expense with data:');
        debugPrint('- User ID: ${expenseRequest.userId}');
        debugPrint('- Description: ${expenseRequest.description}');
        debugPrint('- Amount: ${expenseRequest.amount}');
        debugPrint('- Date: ${expenseRequest.date}');
        debugPrint('- Classification: ${expenseRequest.classification}');
        debugPrint('- Payment Mode: ${expenseRequest.paymentMode}');
        debugPrint('- Receipt No: ${expenseRequest.receiptNo ?? 'N/A'}');
        debugPrint('- Note: ${expenseRequest.note ?? 'N/A'}');
        debugPrint('- Proof File: ${expenseRequest.proofFile?.path ?? 'N/A'}');
        debugPrint('- Proof File Type: ${expenseRequest.proofFileType ?? 'N/A'}');

        // Submit expense via API
        final apiService = EmployeeApiService();
        final response = await apiService.submitExpense(expenseRequest);

        if (response.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        response.message ?? 'Expense submitted successfully',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
              ),
            );
            _resetForm();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        response.message ?? 'Failed to submit expense',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error: ${e.toString()}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _descriptionController.clear();
    _amountController.clear();
    _receiptNumberController.clear();
    _notesController.clear();
    setState(() {
      _selectedCategory = 'Fuel';
      _selectedPaymentMethod = 'Cash';
      _selectedDate = DateTime.now();
      _selectedImage = null;
      _selectedVideo = null;
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;
    });
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3080A5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3080A5),
                    size: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    String? prefixText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines ?? 1,
        inputFormatters: label == 'Amount' ? [
          FilteringTextInputFormatter.allow(RegExp(r'^[₹0-9,\.]*')),
        ] : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefixText,
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF3080A5), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.red.shade300),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF3080A5), width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item, style: const TextStyle(fontSize: 12)),
          );
        }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3080A5), size: 16),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12),
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_right, color: Colors.grey.shade600, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaUploadSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt/Proof',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          
          if (_selectedImage != null || _selectedVideo != null) ...[
            // Media Preview
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade50,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    if (_selectedImage != null)
                      Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      )
                    else if (_selectedVideo != null && _isVideoInitialized)
                      VideoPlayer(_videoController!)
                    else
                      const Center(
                        child: CircularProgressIndicator(),
                      ),
                    
                    // Remove button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _removeMedia,
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ),
                    ),
                    
                    // Play button for video
                    if (_selectedVideo != null && _isVideoInitialized)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                if (_videoController!.value.isPlaying) {
                                  _videoController!.pause();
                                } else {
                                  _videoController!.play();
                                }
                              });
                            },
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          
          // Upload buttons with improved design
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade50,
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Media',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, size: 12),
                        label: const Text(
                          'Photo',
                          style: TextStyle(fontSize: 9),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3080A5),
                          side: BorderSide(color: const Color(0xFF3080A5)),
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.videocam, size: 12),
                        label: const Text(
                          'Video',
                          style: TextStyle(fontSize: 9),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3080A5),
                          side: BorderSide(color: const Color(0xFF3080A5)),
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to choose from camera or gallery',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Max: 10MB for photos, 50MB for videos',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF3080A5),
                    size: 18,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Expense Entry',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Fill in the details below to submit your expense',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Basic Information Card
                _buildSectionCard(
                  title: 'Expense Details',
                  icon: Icons.receipt_long,
                  children: [
                    _buildFormField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      hint: 'Enter expense description',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    _buildFormField(
                      controller: _amountController,
                      label: 'Amount',
                      icon: Icons.currency_rupee,
                      hint: '0.00',
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an amount';
                        }
                        // Remove ₹ and commas for validation
                        final cleanValue = value.replaceAll('₹', '').replaceAll(',', '').trim();
                        if (double.tryParse(cleanValue) == null) {
                          return 'Please enter a valid amount';
                        }
                        if (double.parse(cleanValue) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    _buildDateField(),
                  ],
                ),

                // Category and Payment Method Card
                _buildSectionCard(
                  title: 'Classification',
                  icon: Icons.category,
                  children: [
                    _buildDropdownField(
                      label: 'Category',
                      icon: Icons.label,
                      value: _selectedCategory,
                      items: _categories,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    _buildDropdownField(
                      label: 'Payment Method',
                      icon: Icons.payment,
                      value: _selectedPaymentMethod,
                      items: _paymentMethods,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                      },
                    ),
                  ],
                ),

                // Receipt and Notes Card
                _buildSectionCard(
                  title: 'Additional Information',
                  icon: Icons.note_add,
                  children: [
                    _buildFormField(
                      controller: _receiptNumberController,
                      label: 'Receipt Number',
                      icon: Icons.receipt,
                      hint: 'Enter receipt number (optional)',
                    ),
                    _buildFormField(
                      controller: _notesController,
                      label: 'Notes',
                      icon: Icons.note,
                      hint: 'Add any additional notes (optional)',
                      maxLines: 2,
                    ),
                    _buildMediaUploadSection(),
                  ],
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF3080A5)),
                        ),
                        child: TextButton(
                          onPressed: _resetForm,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3080A5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Reset Form',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3080A5), Color(0xFF1E5A7A)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3080A5).withOpacity(0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitExpense,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 14,
                                  width: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit Expense',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 