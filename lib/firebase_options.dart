// File generated for Firebase configuration.
// Generated from google-services.json

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS not configured');
      case TargetPlatform.macOS:
        throw UnsupportedError('macOS not configured');
      case TargetPlatform.windows:
        throw UnsupportedError('Windows not configured');
      case TargetPlatform.linux:
        throw UnsupportedError('Linux not configured');
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBRt4FeCYwoIaAiUbFZjhjZlUDLucYO4Xs',
    appId: '1:77725337513:android:7b7a8b5841a2d7a9bae6b8',
    messagingSenderId: '77725337513',
    projectId: 'itpass-exam-prep',
    storageBucket: 'itpass-exam-prep.firebasestorage.app',
  );
}
