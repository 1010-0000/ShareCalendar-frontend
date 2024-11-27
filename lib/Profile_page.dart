import 'package:flutter/material.dart';
import 'alarm_settings_page.dart';
import 'profile_setting.dart';  // 새로 추가된 import
import 'bottom_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import 'services/firebaseService.dart';
import 'friendManagement_Page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  bool isLoading = true; // 로딩 상태 추가
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // FirebaseService의 getUserData 호출
      final userData = await _firebaseService.getUserNameEmail();
      setState(() {
        userName = userData['name'].toString();
        userEmail = userData['email'].toString();
        isLoading = false;
      });
    } catch (e) {
      print('오류 발생: $e');
      setState(() {
        userName = "오류";
        userEmail = "오류";
      });
    }
  }

  Future<bool> _showConfirmationDialog(BuildContext context, String action) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$action 확인'),
          content: Text('정말 ${action}하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('아니오'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('예'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _handleLogout(BuildContext context) async {
    if (await _showConfirmationDialog(context, '로그아웃')) {
      // Firebase 로그아웃
      await FirebaseAuth.instance.signOut();

      // Provider의 사용자 정보 초기화
      Provider.of<UserProvider>(context, listen: false).clearUser();

      // Implement logout logic here
      Navigator.pushNamedAndRemoveUntil(
          context, "/", (route) => false
      );

    }
  }

  void _handleDeleteAccount(BuildContext context) async {
    if (await _showConfirmationDialog(context, '회원탈퇴')) {
      // Implement account deletion logic here
      Navigator.pushNamedAndRemoveUntil(
          context, "/", (route) => false
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: Colors.grey),
                onPressed: () {
                  Navigator.pushNamed(context,'/profileSetting');
                },
              ),
            ],
          ),
          body:Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // 기존 Profile 섹션 코드...
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Menu items...
                    ListTile(
                      title: Text('알림 설정'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AlarmSettingsPage()),
                        );
                      },
                    ),
                    Divider(),
                    ListTile(
                      title: Text('친구 관리'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        // Implement friend management navigation
                      },
                    ),
                    Divider(),
                    ListTile(
                      title: Text('로그아웃'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () => _handleLogout(context),
                    ),
                    const SizedBox(height: 40),
                    // Delete account button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextButton(
                        onPressed: () => _handleDeleteAccount(context),
                        child: Text(
                          '회원탈퇴',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              BottomIcons(),
            ],
          ),
        ),

        // 로딩 오버레이
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5), // 반투명 배경
            child: Center(
              child: CircularProgressIndicator(), // 로딩 인디케이터
            ),
          ),
      ],
    );
  }
}

