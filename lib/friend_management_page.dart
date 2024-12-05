import 'package:flutter/material.dart';
import './services/friend_service.dart';
class FriendManagementPage extends StatefulWidget {
  const FriendManagementPage({Key? key}) : super(key: key);

  @override
  _FriendManagementPageState createState() => _FriendManagementPageState();
}

class _FriendManagementPageState extends State<FriendManagementPage> {
  final FriendService _friendService = FriendService();
  List<Map<String, String>> friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      List<Map<String, String>> fetchedFriends = await _friendService.fetchFriends();
      setState(() {
        friends = fetchedFriends;
        print("$friends");
      });
    } catch (e) {
      print("친구 목록 불러오기 오류: $e");
    }
  }

  void _showAddFriendDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    // 부모 컨텍스트 저장
    final parentContext = context;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '친구 추가창',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            hintText: '이메일을 입력해주세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('추가'),
            onPressed: () async {
              String email = emailController.text.trim();

              if (email.isEmpty) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('이메일을 입력해주세요.')),
                );
                return;
              }

              Navigator.pop(context); // 다이얼로그 닫기

              final result = await _friendService.addFriend(email);

              // 부모 컨텍스트로 메시지 표시
              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(content: Text(result['email'] ?? '오류 발생')),
              );

              // 친구 목록 새로고침
              if (result['name'] != 'Not Found' && result['name'] != '오류') {
                await _loadFriends();
              }

              print("목록 새로고침 완료");
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('친구 관리'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('친구추가'),
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return _buildFriendItem(friend['name'] ?? '알 수 없음', friend['userId'] ?? '');
        },
      ),
    );
  }

  Widget _buildFriendItem(String nickname, String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '닉네임',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nickname,
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              // 친구 삭제 로직 호출
              await _friendService.deleteFriend(userId);
              _loadFriends(); // 삭제 후 목록 새로고침
            },
          ),
        ],
      ),
    );
  }
}