import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordCheckController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  String? _errorMessage;

  // 랜덤 색상 생성 함수
  String _generateRandomColor() {
    final Random random = Random();
    final int red = random.nextInt(256);
    final int green = random.nextInt(256);
    final int blue = random.nextInt(256);
    return '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  void _validateInputs() async {
    // 빈 칸 체크
    if (_idController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordCheckController.text.isEmpty ||
        _nicknameController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = '모든 항목을 입력해주세요.';
        });
      }
      return;
    }

    // 비밀번호 일치 체크
    if (_passwordController.text != _passwordCheckController.text) {
      if (mounted) {
        setState(() {
          _errorMessage = '비밀번호와 비밀번호 확인 칸이 같지 않습니다.';
        });
      }
      return;
    }

    try {
      // Firebase Auth 회원가입
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _idController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user?.updateDisplayName(_nicknameController.text.trim());

      // Firebase Realtime Database 저장
      final String randomColor = _generateRandomColor();
      DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${userCredential.user?.uid}');
      await userRef.set({
        'email': _idController.text.trim(),
        'name': _nicknameController.text.trim(),
        'color': randomColor,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 성공적으로 완료되었습니다!')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'email-already-in-use') {
            _errorMessage = '이미 사용 중인 이메일입니다.';
          } else if (e.code == 'weak-password') {
            _errorMessage = '비밀번호가 너무 약합니다.';
          } else if (e.code == 'invalid-email') {
            _errorMessage = '잘못된 이메일 형식입니다.';
          } else {
            _errorMessage = '회원가입 실패: ${e.message}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '예기치 못한 오류가 발생했습니다: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                Icons.sync,
                size: 80,
                color: Colors.green[400],
              ),
              const SizedBox(height: 20),
              const Text(
                '너와 나의 Memory',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 60),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  hintText: '아이디',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '비밀번호',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCheckController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: '비밀번호 체크',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  hintText: '닉네임',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _validateInputs,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '회원가입',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _passwordCheckController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }
}