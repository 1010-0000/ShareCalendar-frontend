import 'package:flutter/material.dart';
import 'alarm_settings_page.dart';
import 'friend_management_page.dart';
import 'bottom_icons.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';
import './services/firebaseService.dart';
import './profile_setting.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseService _firebaseService = FirebaseService();
  String userName = '로딩 중...';
  String userEmail = '로딩 중...';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final userInfo = await _firebaseService.getUserNameEmail();
      setState(() {
        userName = userInfo['name'] ?? '이름 없음';
        userEmail = userInfo['email'] ?? '이메일 없음';
      });
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

  Future<void> deleteUserAccount(BuildContext context) async {
    final isConfirmed = await _showConfirmationDialog(context, '회원탈퇴');
    if (!isConfirmed) return;

    try {
      // 모든 구독 해제
      _firebaseService.disposeAllSubscriptions();

      // Firebase에서 사용자 삭제
      await _firebaseService.deleteUserFromFirebase();

      // 로그인 화면으로 이동
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    } catch (e) {
      print('회원탈퇴 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원탈퇴 실패. 관리자에게 문의하세요.')),
      );
    }
  }

  void _handleLogout(BuildContext context) async {
    if (await _showConfirmationDialog(context, '로그아웃')) {
      try {

        // 모든 구독 해제
        _firebaseService.disposeAllSubscriptions();

        // FirebaseService를 사용해 로그아웃 처리
        await _firebaseService.logoutUser();

        // Provider의 사용자 정보 초기화
        Provider.of<UserProvider>(context, listen: false).clearUser();

        // 로그인 화면으로 이동
        Navigator.pushNamedAndRemoveUntil(
          context, "/", (route) => false,
        );
      } catch (e) {
        print('로그아웃 실패: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그아웃 실패. 관리자에게 문의하세요.')),
        );
      }
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
            onPressed: () async {
              // ProfileSetting에서 반환된 데이터를 받음
              final updatedData = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileSetting()),
              );

              // 업데이트된 데이터를 상태에 반영
              if (updatedData != null && mounted) {
                setState(() {
                  userName = updatedData['name'] ?? userName;
                  userEmail = updatedData['email'] ?? userEmail;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FriendManagementPage()),
                    );
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('로그아웃'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () => _handleLogout(context),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextButton(
                    onPressed: () => deleteUserAccount(context),
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

