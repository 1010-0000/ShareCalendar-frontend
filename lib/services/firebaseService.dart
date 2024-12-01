import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../calendar_page.dart';

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
  /// 해당 달에 있는 할일들 모두 가져오는 함수
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

  Future<List<Map<String, dynamic>>> fetchTasksForFilteredUsers(
      List<Map<String, dynamic>> filteredUsers, DateTime selectedMonth) async {
    List<Map<String, dynamic>> result = [];

    // 'yyyy-MM' 형식으로 선택된 월을 포맷팅
    String formattedMonth = DateFormat('yyyy-MM').format(selectedMonth);

    for (var user in filteredUsers) {
      String userId = user['userId'];

      Map<String, dynamic> userInfo = {
        "userId": userId,
        "name": user['name'],
        "isUser": user['isUser'],
      };

      try {
        // Firebase에서 해당 사용자의 tasks 데이터 가져오기
        DataSnapshot tasksSnapshot =
        await database.child("tasks/$userId").get();

        if (tasksSnapshot.exists) {
          // 사용자 ID 하위의 모든 데이터를 가져옴
          final dynamic userTasks = tasksSnapshot.value;

          // userTasks가 Map인지 확인
          if (userTasks is Map<dynamic, dynamic>) {
            // 해당 월의 데이터 필터링
            userTasks.forEach((dateKey, taskData) {
              // dateKey가 해당 월의 데이터인지 확인
              if (dateKey.startsWith(formattedMonth)) {
                if (taskData is Map<dynamic, dynamic>) {
                  result.add({
                    ...userInfo,
                    "title": taskData["title"] ?? "",
                    "memo": taskData["memo"] ?? "",
                    "startDate": taskData["startDate"] ?? "",
                    "endDate": taskData["endDate"] ?? "",
                    "startTime": taskData["startTime"] != null
                        ? "${taskData["startTime"]["hour"].toString().padLeft(2, '0')}:${taskData["startTime"]["minute"].toString().padLeft(2, '0')}"
                        : "",
                    "endTime": taskData["endTime"] != null
                        ? "${taskData["endTime"]["hour"].toString().padLeft(2, '0')}:${taskData["endTime"]["minute"].toString().padLeft(2, '0')}"
                        : "",
                  });
                } else {
                  print("잘못된 데이터 형식 (userId: $userId, dateKey: $dateKey): $taskData");
                }
              }
            });
          } else {
            print("잘못된 데이터 형식 (userId: $userId): $userTasks");
          }
        }
      } catch (e) {
        print("오류 발생 (userId: $userId): $e");
      }
    }

    return result;
  }


  // 사용자의 name, email 조회
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


  // 캘린더 페이지 할일 추가
  Future<void> saveTaskToFirebase(Schedule schedule) async {
    String userId = getCurrentUserId();
    try {

      // StartDate의 날짜만 추출
      String formattedDate = DateFormat('yyyy-MM-dd').format(schedule.startDate);

      // calendar 노드에 해당 달에 유저 정보가 없었으면 추가하기 위한
      String yearMonth = DateFormat('yyyy-MM').format(schedule.startDate);


      // Firebase에 저장할 데이터 구조 생성
      Map<String, dynamic> taskData = {
        "title": schedule.title,
        "memo": schedule.memo,
        "startDate": schedule.startDate.toIso8601String(),
        "endDate": schedule.endDate.toIso8601String(),
        "startTime": {
          "hour": schedule.startTime?.hour ?? 0,
          "minute": schedule.startTime?.minute ?? 0,
        },
        "endTime": {
          "hour": schedule.endTime?.hour ?? 0,
          "minute": schedule.endTime?.minute ?? 0,
        },
      };
      print("유저 id는 : ${userId}");

      // // // 데이터 저장 경로: tasks/{userId}/{formattedDate}/{scheduleId}
      await database
          .child("tasks/$userId/$formattedDate")
          .set(taskData);

      // calendar/{yearMonth}/{userId} 업데이트
      await database.child("calendar/$yearMonth/$userId").set(true);

      print("Task 저장 성공: $taskData");
    } catch (e) {
      print("Task 저장 중 오류 발생: $e");
    }
  }

  // 캘린더 페이지 할일 수정
  Future<void> updateTaskInFirebase(Schedule updatedSchedule) async {
    String userId = getCurrentUserId();
    try {
      // StartDate의 날짜만 추출
      String formattedDate = DateFormat('yyyy-MM-dd').format(updatedSchedule.startDate);

      // Firebase에 저장할 데이터 구조 생성
      Map<String, dynamic> updatedTaskData = {
        "title": updatedSchedule.title,
        "memo": updatedSchedule.memo,
        "startDate": updatedSchedule.startDate.toIso8601String(),
        "endDate": updatedSchedule.endDate.toIso8601String(),
        "startTime": {
          "hour": updatedSchedule.startTime?.hour ?? 0,
          "minute": updatedSchedule.startTime?.minute ?? 0,
        },
        "endTime": {
          "hour": updatedSchedule.endTime?.hour ?? 0,
          "minute": updatedSchedule.endTime?.minute ?? 0,
        },
      };

      // 기존 데이터를 삭제
      await database.child("tasks/$userId/$formattedDate").remove();

      // 업데이트된 데이터를 다시 저장
      await database.child("tasks/$userId/$formattedDate").set(updatedTaskData);

      print("Task 업데이트 성공: $updatedTaskData");
    } catch (e) {
      print("Task 업데이트 중 오류 발생: $e");
    }
  }

  // 캘린더 페이지 삭제 연동
  Future<void> deleteTaskFromFirebase(String scheduleId, DateTime date) async {
    String userId = getCurrentUserId();
    try {
      // StartDate의 날짜만 추출
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Firebase 경로에서 해당 데이터를 삭제
      await database.child("tasks/$userId/$formattedDate").remove();

      print("Task 삭제 성공: Schedule ID = $scheduleId, Date = $formattedDate");
    } catch (e) {
      print("Task 삭제 중 오류 발생: $e");
    }
  }

}
