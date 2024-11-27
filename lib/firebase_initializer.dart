// firebase_initializer.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> initializeFirebase() async {
  try {
    if (kIsWeb) {
      // 웹 플랫폼인 경우 Firebase 초기화
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyA3N-8q3SMRu981feqe_H1-UsPenuCf0SQ",
          authDomain: "sharecalendar-8003f.firebaseapp.com",
          databaseURL: "https://sharecalendar-8003f-default-rtdb.firebaseio.com",
          projectId: "sharecalendar-8003f",
          storageBucket: "sharecalendar-8003f.firebasestorage.app",
          messagingSenderId: "629819734808",
          appId: "1:629819734808:web:10ccb6cfbe7a4b2976fc6d",
          measurementId: "G-4ZKV5N6C22",
        ),
      );
    } else {
      // 모바일 플랫폼인 경우 Firebase 초기화
      await Firebase.initializeApp();
    }
  } catch (e) {
    print('Firebase 초기화 실패: $e');
  }
}
