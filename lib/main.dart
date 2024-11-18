import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sharecalendar_app/Main_Page.dart';
import 'package:sharecalendar_app/sign_up_screen.dart';
import 'calendar_page.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(MyApp());
  } catch (e) {
    print('Firebase 초기화 실패: $e');
  }
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
        '/MainPage': (context) => MainPage(),
      },
    );
  }
}