import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/employee_storage_service.dart';
import '../../services/driver_api_service.dart';
import '../../models/employee_model.dart';
import '../../models/activity_log_model.dart';

class EmployeeActivitiesScreen extends StatefulWidget {
  final bool showBackButton;
  
  const EmployeeActivitiesScreen({
    super.key,
    this.showBackButton = true,
  });

  @override
  State<EmployeeActivitiesScreen> createState() => _EmployeeActivitiesScreenState();
}

class _EmployeeActivitiesScreenState extends State<EmployeeActivitiesScreen> {
  List<ActivityLog> _allActivities = [];
  List<ActivityLog> _filteredActivities = [];
  bool _isLoading = true;
  String? _error;
  Employee? _currentEmployee;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Speech to text variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
    _searchController.addListener(_onSearchChanged);
    _initializeSpeech();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      _speechEnabled = false;
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _searchController.text = result.recognizedWords;
              _isListening = false;
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _loadEmployeeData() async {
    final employee = await EmployeeStorageService.getEmployeeData();
    if (mounted) {
      setState(() {
        _currentEmployee = employee;
      });
      
      if (employee != null) {
        await _loadAllActivities(employee.id);
      }
    }
  }

  Future<void> _loadAllActivities(int userId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('Loading all activities for user ID: $userId');
      final response = await EmployeeApiService().getRecentActivities(
        userId: userId,
        userType: 'users',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (response.success) {
            _allActivities = response.data?.data ?? [];
            _filteredActivities = List.from(_allActivities);
            debugPrint('Loaded ${_allActivities.length} activities');
          } else {
            _error = response.message;
            debugPrint('Failed to load activities: ${response.message}');
          }
        });
      }
    } catch (e) {
      debugPrint('Exception loading activities: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load activities';
        });
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      if (_searchQuery.isEmpty) {
        _filteredActivities = List.from(_allActivities);
      } else {
        final query = _searchQuery.toLowerCase();
        _filteredActivities = _allActivities.where((activity) {
          return activity.operation.toLowerCase().contains(query) ||
                 activity.operationDescription.toLowerCase().contains(query) ||
                 activity.userName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3080A5);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
          'All Activities',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF3080A5),
                size: 18,
              ),
            ),
            onPressed: () {
              if (_currentEmployee != null) {
                _loadAllActivities(_currentEmployee!.id);
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Voice search button
                        if (_speechEnabled)
                          IconButton(
                            icon: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isListening 
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: _isListening ? Colors.red : Colors.grey[600],
                                size: 20,
                              ),
                            ),
                            onPressed: _isListening ? _stopListening : _startListening,
                            tooltip: _isListening ? 'Stop listening' : 'Voice search',
                          ),
                        // Clear button
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey[600]),
                            onPressed: () {
                              _searchController.clear();
                            },
                            tooltip: 'Clear search',
                          ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                // Voice search indicator
                if (_isListening)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Listening... Speak now',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Voice search hint
                if (!_speechEnabled && _allActivities.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Voice search not available on this device',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Activity Count
          if (!_isLoading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Text(
                    '${_filteredActivities.length} activities',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text(
                      'filtered from ${_allActivities.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          
          // Content
          Expanded(
            child: _buildContent(primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color primaryBlue) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading activities...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load activities',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_currentEmployee != null) {
                  _loadAllActivities(_currentEmployee!.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filteredActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.inbox_outlined,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty ? 'No matching activities' : 'No activities found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'Try adjusting your search terms'
                  : 'Activities will appear here when available',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_currentEmployee != null) {
          await _loadAllActivities(_currentEmployee!.id);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredActivities.length,
        itemBuilder: (context, index) {
          final activity = _filteredActivities[index];
          return _buildActivityCard(activity, index == _filteredActivities.length - 1);
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityLog activity, bool isLast) {
    final color = _getActivityColor(activity);
    final icon = _getActivityIcon(activity);
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Activity Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Activity Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Title and Time
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatActivityTitle(activity.operation),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatActivityTime(activity.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Activity Description
                  Text(
                    activity.operationDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Activity Meta
                  Row(
                    children: [
                      if (activity.userName.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            activity.userName,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ID: ${activity.id}',
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatActivityTitle(String operation) {
    switch (operation.toLowerCase()) {
      case 'testdrive status update':
        return 'Test Drive Status Updated';
      case 'request for testdrive':
        return 'Test Drive Request';
      case 'expense submitted':
        return 'Expense Submitted';
      case 'expense approved':
        return 'Expense Approved';
      case 'expense rejected':
        return 'Expense Rejected';
      default:
        return operation.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');
    }
  }

  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    if (dateTime.year == now.year) {
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    } else {
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    }
  }

  IconData _getActivityIcon(ActivityLog activity) {
    if (activity.tableName == 'expenses') return Icons.receipt_outlined;
    if (activity.operation.toLowerCase().contains('canceled') || 
        activity.operationDescription.toLowerCase().contains('canceled')) return Icons.cancel_outlined;
    if (activity.operation.toLowerCase().contains('completed') || 
        activity.operationDescription.toLowerCase().contains('completed')) return Icons.check_circle_outline;
    if (activity.operation.toLowerCase().contains('rescheduled') || 
        activity.operationDescription.toLowerCase().contains('rescheduled')) return Icons.schedule_outlined;
    if (activity.operation.toLowerCase().contains('request for testdrive') || 
        activity.operationDescription.toLowerCase().contains('testdrive request')) return Icons.directions_car_outlined;
    if (activity.operation.toLowerCase().contains('status update')) return Icons.update_outlined;
    return Icons.info_outline;
  }

  Color _getActivityColor(ActivityLog activity) {
    if (activity.tableName == 'expenses') return Colors.blue;
    if (activity.operation.toLowerCase().contains('canceled') || 
        activity.operationDescription.toLowerCase().contains('canceled')) return Colors.red;
    if (activity.operation.toLowerCase().contains('completed') || 
        activity.operationDescription.toLowerCase().contains('completed')) return Colors.green;
    if (activity.operation.toLowerCase().contains('rescheduled') || 
        activity.operationDescription.toLowerCase().contains('rescheduled')) return Colors.orange;
    if (activity.operation.toLowerCase().contains('request for testdrive') || 
        activity.operationDescription.toLowerCase().contains('testdrive request')) return Colors.purple;
    if (activity.operation.toLowerCase().contains('status update')) return Colors.indigo;
    return Colors.grey;
  }
} 