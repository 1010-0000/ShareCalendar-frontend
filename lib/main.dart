import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sharecalendar_app/Main_Page.dart';
import 'package:sharecalendar_app/Profile_page.dart';
import 'package:sharecalendar_app/profile_setting.dart';
import 'package:sharecalendar_app/sign_up_screen.dart';
import 'calendar_page.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:html' as html; // 웹 관련 코드 처리

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (html.window.location.protocol.contains("http")) {
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
            measurementId: "G-4ZKV5N6C22"
        ),
      );
    } else {
      // 모바일 플랫폼인 경우
      await Firebase.initializeApp();
    }

  } catch (e) {
    print('Firebase 초기화 실패: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Calendar',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ko', ''),
        Locale('en', ''),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/calendar': (context) => CalendarPage(),
        '/signup': (context) => SignUpScreen(),
        '/mainPage': (context) => MainPage(),
        '/profile': (context) => ProfilePage(),
        '/profileSetting': (context) => ProfileSetting(),
      },
    );
  }
}