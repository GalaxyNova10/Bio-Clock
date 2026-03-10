export 'local_ml_service_mobile.dart' // Default to mobile implementation
    if (dart.library.html) 'local_ml_service_web.dart'; // Fallback to web implementation if running in browser
