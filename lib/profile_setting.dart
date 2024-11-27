import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class ProfileSetting extends StatefulWidget {
  const ProfileSetting({Key? key}) : super(key: key);

  @override
  State<ProfileSetting> createState() => _ProfileSettingState();
}

class _ProfileSettingState extends State<ProfileSetting> {
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  bool isLoading = true; // 로딩 상태 추가
  String userId = '';
  String name = "";
  String birthDate = "2001.08.25";
  String gender = "남성";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 정보 가져오기
  Future<void> _loadUserData() async {
    try {
      // // Provider에서 userId 가져오기
      // userId = Provider.of<UserProvider>(context, listen: false).userId ?? '';

      // Firebase Authentication을 통해 현재 로그인한 사용자 가져오기
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception("로그인된 사용자가 없습니다.");
      }

      // 사용자 ID
      userId = currentUser.uid;

      if (userId.isEmpty) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // Firebase에서 사용자 정보 가져오기
      final userSnapshot = await database.child('users/$userId').get();

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);

        setState(() {
          name = userData['name'] ?? '이름 없음';
          // birthDate = userData['birthDate'] ?? '생년월일 없음';
          // gender = userData['gender'] ?? '성별 없음';
        });
      } else {
        throw Exception('사용자 데이터를 찾을 수 없습니다.');
      }
      // 리턴값을 다른 상태 변수에 저장하고 화면에 표시하고 싶다면 setState 사용
      setState(() {
        isLoading = false; // 데이터 로드 완료
      });
    } catch (e) {
      print('오류 발생: $e');
    }
  }

  Future<void> _saveUserData() async {
    try {
      if (userId.isEmpty) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // Firebase에 수정된 데이터 저장
      await database.child('users/$userId').update({
        'name': name,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필이 저장되었습니다.')),
      );

      Navigator.pushNamed(context, '/profile');
    } catch (e) {
      print('오류 발생: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 저장 중 오류가 발생했습니다.')),
      );
    }
  }

  Widget _buildProfileItem({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              value,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.edit,
              color: Colors.grey,
              size: 20,
            ),
            onTap: onTap,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _showEditDialog(String label, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$label 수정'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text);
                Navigator.pop(context);
              },
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showBirthGenderDialog() {
    TextEditingController birthController = TextEditingController(text: birthDate);
    String selectedGender = gender;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('생년월일/성별 수정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: birthController,
                    decoration: InputDecoration(
                      labelText: '생년월일',
                      hintText: 'YYYY.MM.DD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: InputDecoration(
                      labelText: '성별',
                      border: OutlineInputBorder(),
                    ),
                    items: ['남성', '여성'].map((String gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() => selectedGender = value!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      birthDate = birthController.text;
                      gender = selectedGender;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '프로필',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveUserData,
            child: Text(
              '저장',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '프로필 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            _buildProfileItem(
              context: context,
              label: '닉네임',
              value: name,
              onTap: () => _showEditDialog('닉네임', name, (newValue) {
                setState(() => name = newValue);
              }),
            ),
            _buildProfileItem(
              context: context,
              label: '생년월일/성별',
              value: '$birthDate / $gender',
              onTap: () => _showBirthGenderDialog(),
            ),
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5), // 배경을 어둡게 처리
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}