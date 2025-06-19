class MapsConfig {
  // Google Maps API Key - Replace with your actual API key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  
  // Map ID for advanced features
  static const String mapId = 'varenium_map_id';
  
  // Default location (Mumbai, India)
  static const double defaultLatitude = 19.0760;
  static const double defaultLongitude = 72.8777;
  
  // Map settings
  static const double defaultZoom = 12.0;
  static const double currentLocationZoom = 15.0;
  
  // Geocoding settings
  static const int geocodingTimeoutSeconds = 10;
  static const int locationTimeoutSeconds = 10;
  
  // Check if API key is configured
  static bool get isApiKeyConfigured {
    return googleMapsApiKey.isNotEmpty && 
           googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  }
  
  // Get API key for Android
  static String get androidApiKey {
    return googleMapsApiKey;
  }
  
  // Get API key for iOS
  static String get iosApiKey {
    return googleMapsApiKey;
  }
} 