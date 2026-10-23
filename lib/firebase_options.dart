import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyClV9dhfMNiRMo1uATgR3hQLjcGOL6P_HE',
    appId: '1:740240029076:android:ed64bd0d8ecb5a2e1d4b81',
    messagingSenderId: '740240029076',
    projectId: 'changa-app-87ed8',
    storageBucket: 'changa-app-87ed8.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyClV9dhfMNiRMo1uATgR3hQLjcGOL6P_HE',
    appId: '1:740240029076:android:ed64bd0d8ecb5a2e1d4b81',
    messagingSenderId: '740240029076',
    projectId: 'changa-app-87ed8',
    storageBucket: 'changa-app-87ed8.firebasestorage.app',
  );
}
