// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA3N-8q3SMRu981feqe_H1-UsPenuCf0SQ',
    appId: '1:629819734808:web:10ccb6cfbe7a4b2976fc6d',
    messagingSenderId: '629819734808',
    projectId: 'sharecalendar-8003f',
    authDomain: 'sharecalendar-8003f.firebaseapp.com',
    storageBucket: 'sharecalendar-8003f.firebasestorage.app',
    measurementId: 'G-4ZKV5N6C22',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAG9UhSzII6eCnxxNKI13lXvZWdGzHGMco',
    appId: '1:629819734808:android:a834eed1b1f04a7576fc6d',
    messagingSenderId: '629819734808',
    projectId: 'sharecalendar-8003f',
    storageBucket: 'sharecalendar-8003f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCmk2iav_DGfveRGNEFMr8Bs0Bj8Q3AIY8',
    appId: '1:629819734808:ios:bd7eef726db9593f76fc6d',
    messagingSenderId: '629819734808',
    projectId: 'sharecalendar-8003f',
    storageBucket: 'sharecalendar-8003f.firebasestorage.app',
    iosBundleId: 'com.example.sharecalendarApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCmk2iav_DGfveRGNEFMr8Bs0Bj8Q3AIY8',
    appId: '1:629819734808:ios:bd7eef726db9593f76fc6d',
    messagingSenderId: '629819734808',
    projectId: 'sharecalendar-8003f',
    storageBucket: 'sharecalendar-8003f.firebasestorage.app',
    iosBundleId: 'com.example.sharecalendarApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA3N-8q3SMRu981feqe_H1-UsPenuCf0SQ',
    appId: '1:629819734808:web:64d7c9553954136e76fc6d',
    messagingSenderId: '629819734808',
    projectId: 'sharecalendar-8003f',
    authDomain: 'sharecalendar-8003f.firebaseapp.com',
    storageBucket: 'sharecalendar-8003f.firebasestorage.app',
    measurementId: 'G-G4PXRJC358',
  );
}
