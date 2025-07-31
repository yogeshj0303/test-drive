import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/test_drive_model.dart';
import '../models/user_model.dart';

class UserTestDrivesProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  List<TestDriveListResponse> _allTestDrives = [];
  bool _isLoading = false;
  String? _errorMessage;
  User? _currentUser;
  bool _initialized = false;
  bool _isFetching = false;
  DateTime? _lastFetchTime;
  static const Duration _cacheValidDuration = Duration(minutes: 10); // Increased cache duration
  
  // Enhanced caching properties
  String? _lastDataHash; // Hash of last fetched data for change detection
  bool _hasDataChanged = false; // Track if data has changed since last fetch
  Map<String, DateTime> _lastScreenAccess = {}; // Track when each screen was last accessed
  static const Duration _screenCacheDuration = Duration(minutes: 2); // Cache per screen
  String? _lastApiMessage; // Store last API message

  // Automatically fetch test drives once on provider creation
  UserTestDrivesProvider() {
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => _initializeData());
  }

  List<TestDriveListResponse> get allTestDrives => _allTestDrives;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  bool get initialized => _initialized;
  bool get hasDataChanged => _hasDataChanged;
  String? get lastApiMessage => _lastApiMessage;

  List<TestDriveListResponse> get pendingTestDrives =>
      _allTestDrives.where((td) => (td.status ?? '').toLowerCase() == 'pending').toList();
  List<TestDriveListResponse> get approvedTestDrives =>
      _allTestDrives.where((td) => (td.status ?? '').toLowerCase() == 'approved').toList();
  List<TestDriveListResponse> get rescheduledTestDrives =>
      _allTestDrives.where((td) => (td.status ?? '').toLowerCase() == 'rescheduled').toList();
  List<TestDriveListResponse> get rejectedTestDrives =>
      _allTestDrives.where((td) => (td.status ?? '').toLowerCase() == 'rejected').toList();
  List<TestDriveListResponse> get completedTestDrives =>
      _allTestDrives.where((td) => (td.status ?? '').toLowerCase() == 'completed').toList();

  // Initialize data - called once when provider is created
  Future<void> _initializeData() async {
    if (_initialized || _isFetching) return;
    await fetchTestDrives();
  }

  // Check if cache is still valid
  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  // Check if screen-specific cache is valid
  bool _isScreenCacheValid(String screenName) {
    final lastAccess = _lastScreenAccess[screenName];
    if (lastAccess == null) return false;
    return DateTime.now().difference(lastAccess) < _screenCacheDuration;
  }

  // Generate hash for data change detection
  String _generateDataHash(List<TestDriveListResponse> data) {
    // Simple hash based on count and IDs
    final ids = data.map((td) => '${td.id}_${td.status}').join(',');
    return '${data.length}_$ids';
  }

  // Check if data has actually changed
  bool _hasDataActuallyChanged(List<TestDriveListResponse> newData) {
    final newHash = _generateDataHash(newData);
    if (_lastDataHash == null) {
      _lastDataHash = newHash;
      return true; // First time loading
    }
    
    final hasChanged = _lastDataHash != newHash;
    if (hasChanged) {
      _lastDataHash = newHash;
      _hasDataChanged = true;
    }
    return hasChanged;
  }

  // Record screen access for smart caching
  void recordScreenAccess(String screenName) {
    _lastScreenAccess[screenName] = DateTime.now();
  }

  // Smart fetch with change detection
  Future<void> fetchTestDrives({bool forceRefresh = false, String? screenName}) async {
    // Prevent redundant calls
    if (_isFetching) return;
    
    // Use cached data if available and not forcing refresh
    if (!forceRefresh && _isCacheValid && _allTestDrives.isNotEmpty) {
      // If screen-specific cache is valid, don't show loading
      if (screenName != null && _isScreenCacheValid(screenName)) {
        return;
      }
    }

    _isFetching = true;
    _isLoading = true;
    _errorMessage = null;
    _lastApiMessage = null;
    notifyListeners();

    try {
      _currentUser = await _storageService.getUser();
      if (_currentUser == null) {
        _errorMessage = 'User not found. Please login again.';
        _lastApiMessage = _errorMessage;
        _isLoading = false;
        _isFetching = false;
        notifyListeners();
        return;
      }

      final response = await _apiService.getUserTestDrives(_currentUser!.id);
      
      if (response.success) {
        final newData = response.data ?? [];
        final dataChanged = _hasDataActuallyChanged(newData);
        
        _allTestDrives = newData;
        _initialized = true;
        _lastFetchTime = DateTime.now();
        
        // Record screen access if provided
        if (screenName != null) {
          recordScreenAccess(screenName);
        }
        
        _isLoading = false;
        _isFetching = false;
        _lastApiMessage = null;
        notifyListeners();
        
        // Only notify if data actually changed
        if (dataChanged) {
          // Test drive data changed - notifying listeners
        } else {
          // Test drive data unchanged - using cached data
        }
      } else {
        _errorMessage = response.message;
        _lastApiMessage = response.message;
        _isLoading = false;
        _isFetching = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load test drives.';
      _lastApiMessage = _errorMessage;
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // Manual refresh - forces fresh data
  Future<void> refresh() async {
    await fetchTestDrives(forceRefresh: true);
  }

  // Smart refresh - only fetches if cache is stale or data has changed
  Future<void> smartRefresh({String? screenName}) async {
    if (!_isCacheValid || _hasDataChanged) {
      await fetchTestDrives(screenName: screenName);
    } else if (screenName != null && !_isScreenCacheValid(screenName)) {
      // Screen cache is stale, refresh
      await fetchTestDrives(screenName: screenName);
    }
  }

  // Optimistic update - immediately update UI, then sync with server
  void optimisticUpdate(TestDriveListResponse updatedTestDrive) {
    final index = _allTestDrives.indexWhere((td) => td.id == updatedTestDrive.id);
    if (index != -1) {
      _allTestDrives[index] = updatedTestDrive;
      _hasDataChanged = true;
      notifyListeners();
    }
  }

  // Remove test drive from cache (for completed/cancelled test drives)
  void removeTestDrive(int testDriveId) {
    _allTestDrives.removeWhere((td) => td.id == testDriveId);
    _hasDataChanged = true;
    notifyListeners();
  }

  // Add new test drive to cache
  void addTestDrive(TestDriveListResponse testDrive) {
    _allTestDrives.add(testDrive);
    _hasDataChanged = true;
    notifyListeners();
  }

  // Update specific test drive in cache
  void updateTestDrive(TestDriveListResponse updatedTestDrive) {
    final index = _allTestDrives.indexWhere((td) => td.id == updatedTestDrive.id);
    if (index != -1) {
      _allTestDrives[index] = updatedTestDrive;
      _hasDataChanged = true;
      notifyListeners();
    }
  }

  // Clear cache and data
  void clearCache() {
    _allTestDrives = [];
    _initialized = false;
    _lastFetchTime = null;
    _lastDataHash = null;
    _hasDataChanged = false;
    _lastScreenAccess.clear();
    _errorMessage = null;
    notifyListeners();
  }

  // Get cached data without triggering a fetch
  List<TestDriveListResponse> getCachedData() {
    return List.from(_allTestDrives);
  }

  // Check if we have valid cached data
  bool get hasValidCache {
    return _isCacheValid && _allTestDrives.isNotEmpty;
  }

  // Get loading state for specific screen
  bool isLoadingForScreen(String screenName) {
    return _isLoading;
  }
} 