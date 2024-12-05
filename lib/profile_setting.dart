import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import './services/firebaseService.dart';

class ProfileSetting extends StatefulWidget {
  const ProfileSetting({Key? key}) : super(key: key);

  @override
  State<ProfileSetting> createState() => _ProfileSettingState();
}

class _ProfileSettingState extends State<ProfileSetting> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = true;
  String name = "";
  String email = "";
  String color = "#000000";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 사용자 정보 가져오기
  Future<void> _loadUserData() async {
    try {
      final userData = await _firebaseService.fetchUserData();
      setState(() {
        name = userData['name'] ?? '이름 없음';
        email = userData['email'] ?? '이메일 없음';
        color = userData['color'] ?? '#000000';
        isLoading = false;
      });
    } catch (e) {
      print('오류 발생: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveUserData() async {
    try {
      final updatedData = {
        'name': name,
        'email': email,
        'color': color,
      };

      await _firebaseService.saveUserData(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필이 저장되었습니다.')),
      );

      // 수정된 데이터 반환
      Navigator.pop(context, updatedData);
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

  void _showColorPickerDialog() {
    // 현재 색상을 Color 객체로 변환
    Color currentColor = Color(int.parse(color.replaceAll('#', '0xff')));
    TextEditingController colorController = TextEditingController(text: color);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('색상 선택'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // 색상 표 피커
                BlockPicker(
                  pickerColor: currentColor,
                  onColorChanged: (Color pickedColor) {
                    setState(() {
                      // 16진수 색상 코드로 변환 (# 포함)
                      color = '#${pickedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                      colorController.text = color;
                    });
                  },
                ),
                SizedBox(height: 16),
                // 16진수 색상 코드 직접 입력 텍스트필드
                TextField(
                  controller: colorController,
                  decoration: InputDecoration(
                    labelText: '16진수 색상 코드 (#000000)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    // 입력된 색상 코드 검증
                    if (value.startsWith('#') && value.length == 7) {
                      try {
                        setState(() {
                          color = value;
                          currentColor = Color(int.parse(value.replaceAll('#', '0xff')));
                        });
                      } catch (e) {
                        // 잘못된 색상 코드 처리
                        print('잘못된 색상 코드: $value');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '프로필 설정',
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
                  label: '이메일',
                  value: email,
                  onTap: () => _showEditDialog('이메일', email, (newValue) {
                    setState(() => email = newValue);
                  }),
                ),
                _buildProfileItem(
                  context: context,
                  label: '색상',
                  value: color,
                  onTap: _showColorPickerDialog,
                ),
              ],
            ),
          ),
        ),
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}