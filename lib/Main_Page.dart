import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'bottom_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final DatabaseReference database = FirebaseDatabase.instance.ref(); //파이어베이스 인스턴스 참조
  List<Map<String, dynamic>> _tasksByUser = []; // 유저 및 친구들 정보 및 할일들 담은 List
  bool isLoading = true; // 로딩 상태 추가
  late DateTime selectedDate;
  late List<DateTime> weekDays;
  final dateFormat = DateFormat('M월 d일', 'ko_KR');
  final loggedInUser = '희찬';
  final otherUsers = ['선준', '건우', '문권', '희찬'];



  @override
  void initState() {
    super.initState();
    _initializeData();
    selectedDate = DateTime.now();
    _generateWeekDays();

  }

  void _generateWeekDays() {
    DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  // 유저 및 유저의 친구목록 init
  Future<void> _initializeData() async {
    setState(() {
      isLoading = true; // 로딩 시작
    });

    try {
      final userAndFriends = await fetchUserAndFriends(); // fetchUserAndFriends 호출
      // * userAndFriends값 어딘가에 저장
      // print("유저 및 친구들 정보 초기화 : ${userAndFriends}"); // 리턴값 출력

      // tasks 데이터 가져오기
      final tasks = await fetchTasksWithUserDetails(userAndFriends, selectedDate);
      // print("tasks 데이터: $tasks");

      // 리턴값을 다른 상태 변수에 저장하고 화면에 표시하고 싶다면 setState 사용
      setState(() {
        // 예: _userData = userAndFriends;
        _tasksByUser = tasks;
        isLoading = false; // 데이터 로드 완료
      });

      print("초기화 완료 ${_tasksByUser}");

    } catch (e) {
      print("오류 발생: $e");
    }
  }

  /// 로그인한 사용자 정보와 친구 목록 가져오기
  Future<List<Map<String, dynamic>>> fetchUserAndFriends() async {

    // 사용자 및 친구들 id,이름,사용자여부 담는 객체
    List<Map<String, dynamic>> result=[];

    // Firebase Authentication을 통해 현재 로그인한 사용자 가져오기
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("로그인된 사용자가 없습니다.");
    }

    // 사용자 ID
    String userId = currentUser.uid;

    // 1. 현재 사용자 정보 가져오기
    DataSnapshot userSnapshot = await database.child("users/$userId").get();

    if (!userSnapshot.exists) {
      throw Exception("사용자 정보를 찾을 수 없습니다.");
    }

    // userSnapshot.value가 Map인지 확인 후 변환
    Map<String, dynamic> userData;
    if (userSnapshot.value is Map<dynamic, dynamic>) {
      userData = Map<String, dynamic>.from(userSnapshot.value as Map);
    } else {
      throw Exception("사용자 데이터 형식이 올바르지 않습니다.");
    }

    // 사용자 정보에서 필요한 값만 추출
    result.add({
      "userId": userId,
      "name": userData["name"],
      "isUser": true, // 현재 사용자임을 표시
    });

    // 2. 친구 목록 가져오기
    Map<String, dynamic>? friends = userData["friends"] != null
        ? Map<String, dynamic>.from(userData["friends"])
        : {};

    // 친구 이름만 가져오기
    for (String friendId in friends.keys) {
      DataSnapshot friendSnapshot = await database.child("users/$friendId").get();
      if (friendSnapshot.exists) {
        if (friendSnapshot.value is Map<dynamic, dynamic>) {
          Map<String, dynamic> friendData =
          Map<String, dynamic>.from(friendSnapshot.value as Map);
          result.add({
            "userId": friendId,
            "name": friendData["name"], // 이름이 없으면 기본값 설정
            "isUser": false, // 친구임을 표시
          });
        } else {
          print("친구 데이터 형식이 올바르지 않습니다: $friendId");
        }
      }
    }

    // 결과 데이터 구성
    return result;
  }

  Future<List<Map<String, dynamic>>> fetchTasksWithUserDetails(
      List<Map<String, dynamic>> userAndFriends, DateTime selectedDate) async {
    List<Map<String, dynamic>> result = [];
    Map<String, dynamic> tasksByUser = {};

    // 날짜를 'yyyy-MM-dd' 형식으로 포맷팅
    String formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

    // 각 사용자에 대해 tasks 데이터 가져오기
    for (var user in userAndFriends) {
      String userId = user['userId'];
      Map<String, dynamic> userInfo = {
        "userId": userId,
        "name": user['name'],
        "isUser": user['isUser'],
      };

      try {
        // 해당 사용자의 tasks 데이터 가져오기
        DataSnapshot tasksSnapshot = await database.child("tasks/$userId/$formattedDate").get();

        if (tasksSnapshot.exists) {
          // tasksByUser[userId] = tasksSnapshot.value; // tasks 데이터 저장
          Map<dynamic, dynamic> task = tasksSnapshot.value as Map<dynamic, dynamic>;

          // print("tasks : ${tasks}");
          // // 각 task에 사용자 정보 병합

            result.add({
              ...userInfo,
              "memo": task["memo"] ?? "",
              "startTime": task["startTime"] ?? "",
              "title": task["title"] ?? "",
          });
        }
      } catch (e) {
        print("오류 발생 (userId: $userId): $e");
        tasksByUser[userId] = {"error": e.toString()};
      }
    }
    return result;
  }



  @override
  Widget build(BuildContext context) {
    final currentDate = dateFormat.format(selectedDate);

    // 일정 데이터 (백엔드 없이 하드코딩)
    final schedules = [
      {
        'date': DateTime.now(),
        'title': '친구 만나기',
        'time': '09:30 - 11:00',
        'owner': '선준',
      },
      {
        'date': DateTime.now(),
        'title': '장보기',
        'time': '10:00 - 12:00',
        'owner': loggedInUser,
      },
      {
        'date': DateTime.now(),
        'title': '운동하기',
        'time': '15:00 - 16:00',
        'owner': '건우',
      },
    ];


    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Welcome Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '반가워요',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 25,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            loggedInUser,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Date Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentDate,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            loggedInUser,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // 일정 표시
                          ..._tasksByUser
                            .map((schedule) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          schedule['title'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              "10:00 - 12:00",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              schedule['name'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: schedule['name'] == "문권"
                                                    ? Colors.green
                                                    : Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          )).toList(),

                          if (_tasksByUser.isEmpty)
                            const Text(
                              '일정 없음',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Week Calendar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: weekDays
                                .map((date) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedDate = date;
                                  _generateWeekDays();
                                });
                                _initializeData(); // 새로운 날짜에 해당하는 데이터 로드
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: date.year == selectedDate.year &&
                                    date.month == selectedDate.month &&
                                    date.day == selectedDate.day
                                    ? Colors.green
                                    : Colors.grey[200],
                                child: Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: date.year == selectedDate.year &&
                                        date.month == selectedDate.month &&
                                        date.day == selectedDate.day
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),
                BottomIcons(),
              ],
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

