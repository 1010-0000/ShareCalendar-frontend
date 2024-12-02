import 'package:flutter/material.dart';
import 'alarm_settings_page.dart';
import 'profile_setting.dart';  // 새로 추가된 import
import 'bottom_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  String userName = '로딩 중...';
  String userEmail = '로딩 중...';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      // // Provider를 통해 userId 가져오기
      // final userId = Provider.of<UserProvider>(context, listen: false).userId;

      // Firebase Authentication을 통해 현재 로그인한 사용자 가져오기
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("로그인된 사용자가 없습니다.");
      }

      // 사용자 ID
      String userId = currentUser.uid;

      if (userId == null) {
        throw Exception('로그인된 사용자가 없습니다.');
        Navigator.pushReplacementNamed(context, '/');
      }

      // Firebase Database에서 사용자 데이터 가져오기
      final userSnapshot = await database.child('users/$userId').get();

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);

        setState(() {
          userName = userData['name'] ?? '이름 없음';
          userEmail = userData['email'] ?? '이메일 없음';
        });
      } else {
        throw Exception('사용자 데이터를 찾을 수 없습니다.');
      }
    } catch (e) {
      print('오류 발생: $e');
      setState(() {
        userName = '오류 발생';
        userEmail = '오류 발생';
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
    return Scaffold(
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
      body: Column(
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
    );
  }


}

