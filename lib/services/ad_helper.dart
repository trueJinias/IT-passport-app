import 'dart:io';

class AdHelper {
  // Official AdMob Test ID for Android Banner
  static String get androidBannerAdUnitId {
    return 'ca-app-pub-3940256099942544/6300978111';
  }

  // Official AdMob Test ID for iOS Banner
  static String get iosBannerAdUnitId {
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return iosBannerAdUnitId;
    } else {
      return '';
    }
  }

  static bool get isSupported {
    return Platform.isAndroid || Platform.isIOS;
  }
}
