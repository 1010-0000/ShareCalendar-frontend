import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FirebaseService {
  // 내부에서 사용할 정적 인스턴스 변수
  static final FirebaseService _instance = FirebaseService._internal();
  final DatabaseReference database = FirebaseDatabase.instance.ref();
  // 외부에서 인스턴스를 가져갈 때 사용하는 factory constructor
  factory FirebaseService() {
    return _instance;
  }
  // 내부에서만 호출할 수 있는 private constructor
  FirebaseService._internal();

  String getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("로그인된 사용자가 없습니다.");
    }
    return currentUser.uid;
  }

  /// 로그인한 사용자 정보와 친구 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchUserAndFriends() async {
    // 사용자 ID 가져오기
    String userId = getCurrentUserId();

    // 1. 현재 사용자 정보 데이터베이스에서 가져오기
    DataSnapshot userSnapshot = await database.child("users/$userId").get();
    if (!userSnapshot.exists) {
      throw Exception("사용자 정보를 찾을 수 없습니다.");
    }

    Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);

    List<Map<String, dynamic>> result = [];

    // 사용자 정보에서 필요한 값만 추출
    result.add({
      "userId": userId,
      "name": userData["name"],
      "isUser": true,
    });

    // 2. 친구 목록 가져오기
    Map<String, dynamic>? friends = userData["friends"] != null
        ? Map<String, dynamic>.from(userData["friends"])
        : {};

    for (String friendId in friends.keys) {
      DataSnapshot friendSnapshot = await database.child("users/$friendId").get();
      if (friendSnapshot.exists) {
        Map<String, dynamic> friendData = Map<String, dynamic>.from(friendSnapshot.value as Map);
        result.add({
          "userId": friendId,
          "name": friendData["name"],
          "isUser": false,
        });
      }
    }

    return result;
  }

  /// calendar/{yearMonth}에 존재하는 사용자 필터링
  Future<List<Map<String, dynamic>>> filterUsersInCalendar(
      List<Map<String, dynamic>> users, String yearMonth) async {
    List<Map<String, dynamic>> filteredUsers = [];

    try {
      for (Map<String, dynamic> user in users) {
        String userId = user['userId'];

        // calendar/{yearMonth}/{userId}가 있는지 확인
        DataSnapshot calendarSnapshot = await database.child('calendar/$yearMonth/$userId').get();
        if (calendarSnapshot.exists) {
          filteredUsers.add(user);
        }
      }

      return filteredUsers;
    } catch (e) {
      print("오류 발생: $e");
      return [];
    }
  }

  /// 필터링된 사용자 ID에 따라 tasks 데이터 가져오기
  Future<List<Map<String, dynamic>>> fetchTasksForFilteredUsers(
      List<Map<String, dynamic>> filteredUsers, DateTime selectedDate) async {
    List<Map<String, dynamic>> result = [];

    // 날짜를 'yyyy-MM-dd' 형식으로 포맷팅
    String formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    for (var user in filteredUsers) {
      String userId = user['userId'];
      Map<String, dynamic> userInfo = {
        "userId": userId,
        "name": user['name'],
        "isUser" : user['isUser'],
      };

      try {
        // Firebase에서 해당 사용자의 tasks 데이터 가져오기
        DataSnapshot tasksSnapshot =
        await database.child("tasks/$userId/$formattedDate").get();

        if (tasksSnapshot.exists) {
          Map<dynamic, dynamic> taskData = tasksSnapshot.value as Map<dynamic, dynamic>;

          result.add({
            ...userInfo,
            "memo": taskData["memo"] ?? "",
            "startTime": taskData["startTime"] ?? "",
            "title": taskData["title"] ?? "",
          });
        }
      } catch (e) {
        print("오류 발생 (userId: $userId): $e");
      }
    }

    return result;
  }

  Future<Map<String, String>> getUserNameEmail() async {
    try {
      // // Provider를 통해 userId 가져오기
      // final userId = Provider.of<UserProvider>(context, listen: false).userId;

      // 사용자 ID
      String userId = getCurrentUserId();

      if (userId == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // Firebase Database에서 사용자 데이터 가져오기
      final userSnapshot = await database.child('users/$userId').get();

      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
// name과 email만 추출하여 리턴
        return {
          'name': userData['name'] ?? '이름 없음',
          'email': userData['email'] ?? '이메일 없음',
        };

      } else {
        throw Exception('사용자 데이터를 찾을 수 없습니다.');
      }
    } catch (e) {
      print('오류 발생: $e');
      // 기본값 반환
      return {
        'name': '오류 발생',
        'email': '오류 발생',
      };

    }
  }
}
