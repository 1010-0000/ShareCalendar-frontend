import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'alarm_settings_page.dart';
import 'profile_setting.dart';  // 새로 추가된 import
import 'bottom_icons.dart';
class ProfilePage extends StatelessWidget {
  final String username;
  final String userId;

  const ProfilePage({
    Key? key,
    required this.username,
    required this.userId,
  }) : super(key: key);

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
      // Implement logout logic here
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _handleDeleteAccount(BuildContext context) async {
    if (await _showConfirmationDialog(context, '회원탈퇴')) {
      // Implement account deletion logic here
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileSetting(),  // ProfileSetting 페이지로 이동
                ),
              );
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
                        backgroundImage: AssetImage('assets/doraemon.png'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        username,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userId,
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