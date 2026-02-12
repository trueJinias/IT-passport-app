import 'dart:io';

class AdHelper {
  // Replace these with your actual Ad Unit IDs from AdMob Console
  
  // ANDROID IDs
  static String get androidBannerAdUnitId {
    if (errorMessage.isNotEmpty) return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    return 'ca-app-pub-9528984947357055/3010772023'; 
  }

  // iOS IDs (for future use)
  static String get iosBannerAdUnitId {
    if (errorMessage.isNotEmpty) return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    return 'ca-app-pub-YOUR_APP_ID/YOUR_UNIT_ID';
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Always use Test ID for development
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Always use Test ID for development
    } else {
      // Return null or throw? Better to return a dummy or null if we change types.
      // But keeping String return type prevents null.
      // Let's rely on isSupported check.
      return ''; 
    }
  }

  static bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }
  
  // Helper to check if we are in test mode
  // Set to empty string "" to use Real IDs
  static String errorMessage = ""; 
}
