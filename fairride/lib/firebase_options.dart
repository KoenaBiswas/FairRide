// Firebase config for project fareride-d30a8 (Android).
// Values come from google-services.json. Replace by re-running
// `flutterfire configure` if you add iOS or web later.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'FirebaseOptions are only configured for Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvkcQRUijNOdXBfd51XMQgBvZ8rugKrHc',
    appId: '1:221862877706:android:9f377d0f6726451b08ddf3',
    messagingSenderId: '221862877706',
    projectId: 'fareride-d30a8',
    storageBucket: 'fareride-d30a8.firebasestorage.app',
  );
}
