import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sharecalendar_app/Main_Page.dart';
import 'package:sharecalendar_app/Profile_page.dart';
import 'package:sharecalendar_app/profile_setting.dart';
import 'package:sharecalendar_app/sign_up_screen.dart';
import 'calendar_page.dart';
import 'friend_management_page.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_initializer.dart'; // Firebase 초기화 파일
import 'user_provider.dart'; // 위에서 만든 UserProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeFirebase(); // Firebase 초기화 호출
  } catch (e) {
    print('Firebase 초기화 실패: $e');
  }
  runApp( MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => UserProvider()),
    ],
    child: MyApp(),
  ),);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
        '/friend': (context) => FriendManagementPage(),
      },
    );
  }
}