import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final DatabaseReference database = FirebaseDatabase.instance.ref();

  // 현재 사용자 ID 가져오기
  String _getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("로그인된 사용자가 없습니다.");
    }
    return currentUser.uid;
  }

  // 친구 추가
  Future<Map<String,String>> addFriend(String friendEmail) async {
    Map<String, String> friend = {};
    String userId = _getCurrentUserId();
    try {
      // Firebase에서 해당 이메일의 사용자 ID 찾기
      final usersSnapshot = await database.child('users').orderByChild('email').equalTo(friendEmail).get();
      if (usersSnapshot.exists) {
        final Map<String, dynamic> snapshotValue =
        Map<String, dynamic>.from(usersSnapshot.value as Map);
        final friendId = snapshotValue.keys.first;

        // 현재 사용자의 friends 목록에서 이미 추가된 친구인지 확인
        final friendsSnapshot = await database.child('users/$userId/friends/$friendId').get();
        if (friendsSnapshot.exists) {
          return {
            'userId': friendId,
            'name': 'Already Friends',
            'email': '이미 친구로 등록된 사용자입니다.'
          };
        }

        // 1. 현재 사용자(`userId`)의 `friends`에 상대방 추가
        await database.child('users/$userId/friends/$friendId').set(true);

        // 2. 상대방(`friendId`)의 `friends`에 현재 사용자 추가
        final currentUserSnapshot = await database.child('users/$userId/email').get();
        if (currentUserSnapshot.exists) {
          await database.child('users/$friendId/friends/$userId').set(true);
        }
        // 3. 추가된 친구의 정보 반환
        final friendData = Map<String, dynamic>.from(snapshotValue[friendId]);

        return {
          'userId' : friendId,
          'name': friendData['name'] ?? 'Unknown',
          'email': friendData['email'] ?? 'Unknown',
        };

      } else {
        return {
          'name': 'Not Found',
          'email': '해당 이메일의 사용자를 찾을 수 없습니다.'
        };
      }
    } catch (e) {
      print("오류 발생: $e");
      return {
        'name':"오류",
        'email':"오류"
      };
    }
  }

  // 친구 목록 조회
  Future<List<Map<String, String>>> fetchFriends() async {
    String userId = _getCurrentUserId();
    final friendsSnapshot = await database.child('users/$userId/friends').get();
    if (!friendsSnapshot.exists || friendsSnapshot.value == null) {
      return [];
    }

    final friendIds = Map<String, dynamic>.from(friendsSnapshot.value as Map);
    List<Map<String, String>> friends = [];

    for (String friendId in friendIds.keys) {
      final friendSnapshot = await database.child('users/$friendId').get();
      if (friendSnapshot.exists && friendSnapshot.value != null) {
        final friendData = Map<String, dynamic>.from(friendSnapshot.value as Map);
        friends.add({
          'userId': friendId,
          'name': friendData['name'] ?? '이름 없음',
          'email': friendData['email'] ?? '이메일 없음',
        });
      }
    }

    return friends;
  }

  // 친구 삭제
  Future<void> deleteFriend(String friendId) async {
    String userId = _getCurrentUserId();

    try {
      final friendSnapshot = await database.child('users/$userId/friends/$friendId').get();
      if (!friendSnapshot.exists) {
        throw Exception('삭제할 친구가 존재하지 않습니다.');
      }

      // 현재 사용자의 friends 목록에서 삭제
      final userFriendPath = database.child('users/$userId/friends/$friendId');
      final friendFriendPath = database.child('users/$friendId/friends/$userId');

      // 트랜잭션으로 양쪽 삭제 처리
      await Future.wait([
        userFriendPath.remove(),
        friendFriendPath.remove(),
      ]);

      print('친구 삭제 성공: $friendId');
    } catch (e) {
      print('친구 삭제 중 오류 발생: $e');
      throw Exception('친구 삭제 중 오류가 발생했습니다.');
    }
  }
}
