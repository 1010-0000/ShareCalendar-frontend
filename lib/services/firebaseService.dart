import 'dart:async';

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

  final Map<String, StreamSubscription> _globalSubscriptions = {};

  void addSubscription(String key, StreamSubscription subscription) {
    _globalSubscriptions[key]?.cancel(); // 기존 구독 해제
    _globalSubscriptions[key] = subscription;
  }

  void disposeAllSubscriptions() {
    _globalSubscriptions.forEach((_, subscription) => subscription.cancel());
    _globalSubscriptions.clear();
  }

  String getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("로그인된 사용자가 없습니다.");
    }
    return currentUser.uid;
  }

  /// 로그인한 사용자와 친구의 id들 반환
  Future<List<String>> getUserAndFriendIds() async {
    String userId = getCurrentUserId();
    List<String> userAndFriendIds = [userId]; // 로그인한 사용자 포함

    try {
      // 사용자 데이터 가져오기
      DataSnapshot userSnapshot = await FirebaseDatabase.instance.ref('users/$userId').get();
      if (userSnapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        if (userData.containsKey('friends')) {
          Map<String, dynamic> friends = Map<String, dynamic>.from(userData['friends']);
          userAndFriendIds.addAll(friends.keys); // 친구 ID 추가
        }
      }
    } catch (e) {
      print('사용자 및 친구 목록 가져오기 오류: $e');
    }

    return userAndFriendIds;
  }

  /// 사용자 정보 수정
  Future<void> saveUserData(Map<String, dynamic> updatedData) async {
    try {
      String userId = getCurrentUserId(); // 현재 로그인된 사용자 ID 가져오기
      await database.child('users/$userId').update(updatedData);
      print('사용자 데이터 저장 성공');
    } catch (e) {
      print('사용자 데이터 저장 실패: $e');
      throw e; // 필요 시 예외를 다시 던져 처리
    }
  }

  /// 로그인 사용자 정보
  Future<Map<String, dynamic>> fetchUserData() async {
    final String userId = getCurrentUserId();
    final DataSnapshot userSnapshot = await FirebaseDatabase.instance.ref().child('users/$userId').get();

    if (!userSnapshot.exists) {
      throw Exception("사용자 데이터를 찾을 수 없습니다.");
    }

    return Map<String, dynamic>.from(userSnapshot.value as Map);
  }

  /// 사용자 로그아웃 처리
  Future<void> logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      print("로그아웃 성공");
    } catch (e) {
      print("로그아웃 중 오류 발생: $e");
      throw Exception("로그아웃 중 오류가 발생했습니다.");
    }
  }

  /// 데이터베이스에서 유저 삭제
  Future<void> deleteUserFromFirebase() async {
    String userId = getCurrentUserId(); // 현재 사용자 ID 가져오기
    try {
      // 1. Firebase Realtime Database에서 사용자 데이터 삭제
      await database.child("users/$userId").remove();

      // 2. Firebase Authentication에서 사용자 계정 삭제
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
      }

      print("사용자 삭제 성공: $userId");
    } catch (e) {
      print("사용자 삭제 중 오류 발생: $e");
      throw Exception("사용자 삭제 중 오류가 발생했습니다.");
    }
  }

  /// 사용자의 이름과 색깔 정보
  Future<Map<String, String>> getUserNameAndColor(String userId) async {
    try {
      // Firebase에서 주어진 userId의 데이터 가져오기
      DataSnapshot userSnapshot = await database.child("users/$userId").get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        return {
          "name": userData["name"] ?? "사용자 이름 없음",
          "color": userData["color"] ?? "#000000", // 기본값은 검정색
        };
      } else {
        throw Exception("사용자 데이터를 찾을 수 없습니다. (userId: $userId)");
      }
    } catch (e) {
      print("사용자 이름 및 색상 가져오기 중 오류 발생 (userId: $userId): $e");
      return {
        "name": "오류 발생",
        "color": "#000000", // 기본값은 검정색
      };
    }
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
      "color": userData["color"] ?? "#000000", // 기본값은 검정색
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
          "color": friendData["color"] ?? "#000000", // 기본값은 검정색
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

  /// 해당 월에 포함된 할일이 있는 유저들 할일 정보와 합치기
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
        "color": user['color'], // 색상 정보 추가
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
                    "isComplete": taskData["isComplete"] ?? false, // isComplete 값 추가
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
        "isComplete": false, // 기본값으로 추가
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

  Future<void> deleteTaskFromFirebase(String scheduleId, DateTime startDate) async {
    String userId = getCurrentUserId(); // 현재 사용자 ID 가져오기
    try {
      // StartDate의 연월 추출
      String yearMonth = DateFormat('yyyy-MM').format(startDate);

      // StartDate의 날짜만 추출
      String formattedStartDate = DateFormat('yyyy-MM-dd').format(startDate);

      // 1. 시작 날짜의 일정 삭제
      await database.child("tasks/$userId/$formattedStartDate").remove();

      // 2. 해당 달의 남은 일정 확인
      DataSnapshot remainingTasksSnapshot = await database.child("tasks/$userId").get();

      bool hasRemainingTasksInMonth = false;

      if (remainingTasksSnapshot.exists && remainingTasksSnapshot.value is Map) {
        // value를 Map으로 변환하여 처리
        Map<dynamic, dynamic> tasks = remainingTasksSnapshot.value as Map<dynamic, dynamic>;
        tasks.forEach((key, value) {
          // 해당 월에 일정이 있는지 확인
          if (key.startsWith(yearMonth)) {
            hasRemainingTasksInMonth = true;
          }
        });
      }

      // 3. 해당 월에 일정이 없다면 calendar/{yearMonth}/{userId} 삭제
      if (!hasRemainingTasksInMonth) {
        await database.child("calendar/$yearMonth/$userId").remove(); // 노드 삭제
        print("calendar/$yearMonth/$userId 삭제 완료");
      }

      print("Task 삭제 성공: Schedule ID = $scheduleId, Start Date = $formattedStartDate");
    } catch (e) {
      print("Task 삭제 중 오류 발생: $e");
    }
  }

  Future<void> updateTaskCompletionStatus(
      String userId, String date, bool isComplete) async {
    try {
      // 날짜에서 불필요한 문자 제거 (Firebase 경로 허용 형식으로 변환)
      String sanitizedDate = date.split('T').first;

      print("변환된 날짜는 ${sanitizedDate}");
      // Firebase 경로: tasks/유저UID/날짜
      DatabaseReference taskDateRef = FirebaseDatabase.instance
          .ref('tasks/$userId/$sanitizedDate');

      // 날짜 하위에 isComplete 업데이트
      await taskDateRef.update({
        'isComplete': isComplete,
      });

      print('Task completion status for "$sanitizedDate" updated to $isComplete');
    } catch (e) {
      print('Failed to update task completion status: $e');
    }
  }
}
