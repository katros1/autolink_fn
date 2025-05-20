class ApiConfig {
  // Base URL for all API requests
  // Changed from https to http
  static const String baseUrl = 'http://93.127.200.253:8070';
  
  // Helper method to get full endpoint URL
  static String endpoint(String path) {
    // Remove leading slash if present to avoid double slashes
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    return '$baseUrl/$path';
  }
}
