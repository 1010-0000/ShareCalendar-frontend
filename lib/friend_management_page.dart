import 'package:flutter/material.dart';

class FriendManagementPage extends StatelessWidget {
  const FriendManagementPage({Key? key}) : super(key: key);

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
      body: ListView(
        children: [
          _buildFriendItem('건우'),
          _buildFriendItem('희찬'),
          _buildFriendItem('선준'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: '소셜',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '일정',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.green,
      ),
    );
  }

  Widget _buildFriendItem(String nickname) {
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
            onPressed: () {
              // TODO: Implement friend deletion
            },
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '친구 추가창',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                hintText: '아이디를 입력해주세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('추가'),
            onPressed: () {
              // TODO: Implement friend addition logic
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// Friend model for future implementation
class Friend {
  final String id;
  final String nickname;

  Friend({required this.id, required this.nickname});
}

// Future friend management logic
class FriendManager {
  List<Friend> _friends = [];

  void addFriend(Friend friend) {
    // TODO: Implement friend addition logic
    _friends.add(friend);
  }

  void removeFriend(String id) {
    // TODO: Implement friend removal logic
    _friends.removeWhere((friend) => friend.id == id);
  }

  List<Friend> getFriends() {
    return _friends;
  }
}