import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_icons.dart';
import 'schedule_creation_page.dart';
import 'schedule_modify_page.dart';
import 'services/firebaseService.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

// Owner information class
class OwnerInfo {
  final String name;
  final Color color;

  const OwnerInfo({required this.name, required this.color});
}

// Schedule data model
class Schedule {
  final String id;
  final String title;
  final DateTime startDate;
  final TimeOfDay? startTime;
  final DateTime endDate;
  final TimeOfDay? endTime;
  final String memo;
  final OwnerInfo owner;

  Schedule({
    required this.id,
    required this.title,
    required this.startDate,
    this.startTime,
    required this.endDate,
    this.endTime,
    required this.memo,
    required this.owner,
  });

  DateTime get middleDate => startDate.add(Duration(days: (endDate.difference(startDate).inDays / 2).round()));
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool isLoading = true; // 로딩 상태 관리
  final FirebaseService _firebaseService = FirebaseService();
  // DateTime _focusedDay = DateTime.now().subtract(Duration(days: 4));
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showYearMonthPicker = false;
  Map<DateTime, List<Schedule>> events = {};
  int scheduleCount = 0;
  static const String EVENTS_STORAGE_KEY = 'calendar_events';
  String userName = ""; // 사용자 이름 저장
  Color userColor = Colors.green; // 사용자 색상 저장 (기본값)
  late Future<SharedPreferences> _prefs;
  late Map<String, StreamSubscription> _taskSubscriptions; // 여러 사용자 구독 관리

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
    _loadUserData(); // 사용자 데이터 로드
    _loadEvents();
    subscribeToAllTasks(); // 실시간 구독 추가
  }
  late StreamSubscription _taskSubscription;

  void subscribeToAllTasks() async {
    _taskSubscriptions = {}; // 구독 초기화

    try {
      // 로그인한 사용자와 친구들의 UID 가져오기
      List<String> userAndFriendIds = await _firebaseService
          .getUserAndFriendIds();

      for (String userId in userAndFriendIds) {
        DatabaseReference tasksRef = FirebaseDatabase.instance.ref(
            'tasks/$userId');

        _taskSubscriptions[userId] = tasksRef.onValue.listen((event) async {
          print('Firebase 구독 데이터 변경 감지 (사용자: $userId)');

          final data = event.snapshot.value;

          if (data != null && data is Map) {
            // 사용자 정보 가져오기
            Map<String, String> userInfo = await _firebaseService
                .getUserNameAndColor(userId);

            // // 데이터를 Schedule 객체로 변환
            // List<Schedule> schedules = data.entries.map((entry) {
            //   final taskData = entry.value as Map;
            //
            //   return Schedule(
            //     id: entry.key ?? '',
            //     title: taskData["title"] ?? '제목 없음',
            //     startDate: taskData["startDate"] != null
            //         ? DateTime.parse(taskData["startDate"])
            //         : DateTime.now(),
            //     startTime: taskData["startTime"] != null
            //         ? TimeOfDay(
            //       hour: taskData["startTime"]["hour"] ?? 0,
            //       minute: taskData["startTime"]["minute"] ?? 0,
            //     )
            //         : null,
            //     endDate: taskData["endDate"] != null
            //         ? DateTime.parse(taskData["endDate"])
            //         : DateTime.now(),
            //     endTime: taskData["endTime"] != null
            //         ? TimeOfDay(
            //       hour: taskData["endTime"]["hour"] ?? 0,
            //       minute: taskData["endTime"]["minute"] ?? 0,
            //     )
            //         : null,
            //     memo: taskData["memo"] ?? '',
            //     owner: OwnerInfo(
            //       name: userInfo["name"] ?? '알 수 없음',
            //       color: userInfo["color"] != null
            //           ? Color(int.tryParse(
            //           userInfo["color"]!.replaceFirst('#', '0xFF')) ??
            //           0xFF000000)
            //           : Colors.grey,
            //     ),
            //   );
            // }).toList();

            if (mounted) {
              setState(() {
                // 다른 사람의 일정 변경일 경우에는 _loadEvents() 호출
                if (userId != _firebaseService.getCurrentUserId()) {
                  _loadEvents(); // 다른 사용자의 일정 변경 시 _loadEvents 호출
                }
              });
            }
          }
        });
      }
    } catch (e) {
      print('실시간 구독 설정 중 오류 발생: $e');
    }
  }

  @override
  void dispose() {
    _taskSubscription.cancel(); // 스트림 구독 해제
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // 사용자 이름 및 색상 로드
      final userInfo = await _firebaseService.getUserNameAndColor(_firebaseService.getCurrentUserId());
      setState(() {
        userName = userInfo['name'] ?? '사용자';
        userColor = Color(int.parse(userInfo['color']!.replaceFirst('#', '0xFF')));
      });
    } catch (e) {
      print("사용자 데이터 로드 중 오류: $e");
    }
  }

  Future<List<Map<String, dynamic>>> _initializeData() async {
    try {
      final userAndFriends = await _firebaseService.fetchUserAndFriends();
      // print("$userAndFriends");

      final yearMonth = DateFormat('yyyy-MM').format(_focusedDay);
      final filteredUsers = await _firebaseService.filterUsersInCalendar(userAndFriends, yearMonth);

      final tasks = await _firebaseService.fetchTasksForFilteredUsers(filteredUsers, _focusedDay);

      print("tasks 데이터: $tasks");
      return tasks;
    } catch (e) {
      print("오류 발생: $e");
      return [];
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true; // 로딩 시작
    });
    try {
      // tasks 데이터를 가져옴
      final tasks = await _initializeData();
      // print("tasks 데이터: $tasks");
      setState(() {
        events = {}; // 기존 events 초기화

        // UUID 생성기
        final Uuid uuid = Uuid();

        // tasks 데이터를 순회하며 events에 추가
        tasks.forEach((task) {
          final startDate = DateTime.parse(task["startDate"]);
          final endDate = DateTime.parse(task["endDate"]);
          final startTimeParts = task["startTime"].split(':');
          final endTimeParts = task["endTime"].split(':');

          final schedule = Schedule(
            id: uuid.v4(), // 고유한 UUID 생성,
            title: task["title"],
            startDate: startDate,
            startTime: TimeOfDay(
              hour: int.parse(startTimeParts[0]),
              minute: int.parse(startTimeParts[1]),
            ),
            endDate: endDate,
            endTime: TimeOfDay(
              hour: int.parse(endTimeParts[0]),
              minute: int.parse(endTimeParts[1]),
            ),
            memo: task["memo"],
            owner: OwnerInfo(
              name: task["name"],
              color: Color(int.parse(task["color"].replaceFirst('#', '0xFF'))), // Hex color -> Color 변환
            ),
          );
          // startDate부터 endDate까지 events에 추가
          for (int i = 0; i <= endDate.difference(startDate).inDays; i++) {
            final currentDate = startDate.add(Duration(days: i));

            if (events[currentDate] == null) {
              events[currentDate] = [schedule];
            } else {
              events[currentDate]!.add(schedule);
            }
          }
        });

        // 업데이트된 events의 총 일정 수를 계산
        scheduleCount = events.values.fold(0, (sum, list) => sum + list.length);


        // 캘린더에 표시할 스케줄 목록 변환
        List<Schedule> allSchedules = events.values.expand((list) => list).toList();

        // 디스플레이 로직 호출
        displayTasksOnCalendar(allSchedules);
        // print("$events");
      });
    } catch (e) {
      print('Error loading tasks: $e');
    }finally {
      setState(() {
        isLoading = false; // 로딩 종료
      });
    }
  }
  void displayTasksOnCalendar(List<Schedule> schedules) {
    for (var schedule in schedules) {
      // 캘린더에 추가할 로직 구현
      // print("Schedule for calendar: ${schedule.title} (${schedule.owner.name})");
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await _prefs;

      final Map<String, List<Map<String, dynamic>>> encodableData = {};

      events.forEach((date, schedules) {
        encodableData[date.toIso8601String()] = schedules.map((schedule) => {
          'id': schedule.id,
          'title': schedule.title,
          'startDate': schedule.startDate.toIso8601String(),
          'startTime': schedule.startTime != null ? {
            'hour': schedule.startTime!.hour,
            'minute': schedule.startTime!.minute,
          } : null,
          'endDate': schedule.endDate.toIso8601String(),
          'endTime': schedule.endTime != null ? {
            'hour': schedule.endTime!.hour,
            'minute': schedule.endTime!.minute,
          } : null,
          'memo': schedule.memo,
          'owner': {
            'name': schedule.owner.name,
            'color': schedule.owner.color.value,
          },
        }).toList();
      });

      await prefs.setString(EVENTS_STORAGE_KEY, json.encode(encodableData));
    } catch (e) {
      print('Error saving events: $e');
    }
  }

  void _changeMonth(int delta) async {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
      isLoading = true; // 로딩 시작
    });
    await _loadEvents(); // 새로운 달의 데이터를 로드
    setState(() {
      isLoading = false; // 로딩 종료
    });
  }

  void _addEvent(DateTime date, Schedule schedule) async {
    // 로컬 변수 업데이트
    setState(() {
      if (events[date] == null) {
        events[date] = [schedule];
      } else {
        events[date]!.add(schedule);
      }
      scheduleCount++;
    });

    // Firebase와 비동기 동기화
    try {
      await _firebaseService.saveTaskToFirebase(schedule);
    } catch (e) {
      print('Failed to save task to Firebase: $e');
      // Firebase 저장 실패 시 로컬 상태 롤백
      setState(() {
        events[date]?.remove(schedule);
        if (events[date]?.isEmpty ?? false) {
          events.remove(date);
        }
        scheduleCount--;
      });
    }
  }

  void _updateEvent(Schedule updatedSchedule) async {
    // 로컬 변수 업데이트
    setState(() {
      // 기존 일정을 삭제
      events.forEach((date, schedules) {
        schedules.removeWhere((schedule) => schedule.id == updatedSchedule.id);
      });

      // 새로운 일정 추가
      int daysDifference = updatedSchedule.endDate.difference(updatedSchedule.startDate).inDays;
      for (int i = 0; i <= daysDifference; i++) {
        final currentDate = updatedSchedule.startDate.add(Duration(days: i));
        if (events[currentDate] == null) {
          events[currentDate] = [updatedSchedule];
        } else {
          events[currentDate]!.add(updatedSchedule);
        }
      }
    });

    // Firebase와 비동기 동기화
    try {
      await _firebaseService.updateTaskInFirebase(updatedSchedule);
    } catch (e) {
      print('Failed to update task in Firebase: $e');
      // Firebase 업데이트 실패 시 알림 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('일정 업데이트 실패. 인터넷 상태를 확인하세요.')),
      );
    }
  }


  void _deleteEvent(DateTime date, String scheduleId) async {
    Schedule? deletedSchedule;

    // 로컬 변수에서 삭제
    setState(() {
      if (events[date] != null) {
        deletedSchedule = events[date]?.firstWhereOrNull((s) => s.id == scheduleId);
        events[date]?.removeWhere((schedule) => schedule.id == scheduleId);
        if (events[date]?.isEmpty ?? false) {
          events.remove(date);
        }
        scheduleCount--;
      }
    });

    // Firebase와 비동기 동기화
    try {
      await _firebaseService.deleteTaskFromFirebase(scheduleId, date);
    } catch (e) {
      print('Failed to delete task in Firebase: $e');
      // Firebase 삭제 실패 시 로컬 상태 복원
      if (deletedSchedule != null) {
        setState(() {
          if (events[date] == null) {
            events[date] = [deletedSchedule!];
          } else {
            events[date]!.add(deletedSchedule!);
          }
          scheduleCount++;
        });
      }
    }
  }


  List<TableRow> _buildCalendarRows() {
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    List<TableRow> rows = [];
    List<Widget> currentRow = [];

    for (int i = 0; i < firstWeekday; i++) {
      currentRow.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dayOfWeek = (firstWeekday + day - 1) % 7;
      final currentDate = DateTime(_focusedDay.year, _focusedDay.month, day);

      currentRow.add(
        GestureDetector(
          onTap: () => _navigateToSchedulePage(currentDate),
          child: Container(
            height: 105,

            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: dayOfWeek == 0 ? Colors.red : (dayOfWeek == 6 ? Colors.blue : Colors.black),
                      fontSize: 16,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: _buildEventWidgets(currentDate),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (currentRow.length == 7) {
        rows.add(TableRow(children: List.from(currentRow)));
        currentRow.clear();
      }
    }

    while (currentRow.length < 7) {
      currentRow.add(Container());
    }
    if (currentRow.isNotEmpty) {
      rows.add(TableRow(children: currentRow));
    }

    return rows;
  }
  List<Widget> _buildEventWidgets(DateTime currentDate) {
    List<Widget> eventWidgets = [];
    Set<String> displayedEventIds = {}; // 중복 제거를 위한 Set

    // events에서 날짜와 스케줄 리스트를 순회
    events.forEach((date, scheduleList) {
      // 스케줄 리스트를 길이가 긴 순서로 정렬
      scheduleList.sort((a, b) =>
          (b.endDate.difference(b.startDate).inDays + 1)
              .compareTo(a.endDate.difference(a.startDate).inDays + 1));

      for (var schedule in scheduleList) {
        // 스케줄이 현재 날짜에 속하는지 확인
        bool isInSchedulePeriod =
            (currentDate.year == schedule.startDate.year &&
                currentDate.month == schedule.startDate.month &&
                currentDate.day == schedule.startDate.day) ||
                (currentDate.year == schedule.endDate.year &&
                    currentDate.month == schedule.endDate.month &&
                    currentDate.day == schedule.endDate.day) ||
                (currentDate.isAfter(DateTime(schedule.startDate.year,
                    schedule.startDate.month, schedule.startDate.day)) &&
                    currentDate.isBefore(DateTime(schedule.endDate.year,
                        schedule.endDate.month, schedule.endDate.day)));

        // 중복되지 않은 스케줄만 추가
        if (isInSchedulePeriod && !displayedEventIds.contains(schedule.id)) {
          displayedEventIds.add(schedule.id);

          // 스케줄 길이에 따라 이름 표시 날짜 결정
          int scheduleLength = schedule.endDate.difference(schedule.startDate).inDays + 1;
          DateTime middleDate;

          if (scheduleLength % 2 == 0) {
            // 짝수일 경우 중앙 - 1
            middleDate = schedule.startDate.add(Duration(days: (scheduleLength ~/ 2) - 1));
          } else {
            // 홀수일 경우 중앙
            middleDate = schedule.startDate.add(Duration(days: scheduleLength ~/ 2));
          }

          bool isStart = currentDate.isAtSameMomentAs(schedule.startDate);
          bool isEnd = currentDate.isAtSameMomentAs(schedule.endDate);
          bool isMiddle = currentDate.isAtSameMomentAs(middleDate);

          // 스케줄 위젯 추가
          eventWidgets.add(
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: schedule.owner.color.withOpacity(0.2),
                borderRadius: BorderRadius.horizontal(
                  left: isStart ? Radius.circular(4) : Radius.zero,
                  right: isEnd ? Radius.circular(4) : Radius.zero,
                ),
              ),
              child: isMiddle
                  ? Center(
                child: Text(
                  schedule.owner.name, // 중간 날짜에만 이름 표시
                  style: TextStyle(
                    color: schedule.owner.color,
                    fontSize: 12,
                  ),
                ),
              )
                  : null, // 시작일과 종료일에는 이름을 표시하지 않음
            ),
          );
        }
      }
    });

    // 기존의 2개 초과 이벤트 처리 로직 유지
    int totalEvents = displayedEventIds.length;
    if (totalEvents > 2) {
      eventWidgets = eventWidgets.take(2).toList();
      eventWidgets.add(
        Expanded(
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(4),
                right: Radius.circular(4),
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '+${totalEvents - 2}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return eventWidgets;
  }

  void _navigateToSchedulePage(DateTime selectedDate) async {
    // 고유한 일정 ID를 가진 일정만 필터링
    Set<String> uniqueScheduleIds = Set();
    List<Schedule> relatedSchedules = events.values
        .expand((schedules) => schedules)
        .where((schedule) =>
          (selectedDate.isAtSameMomentAs(schedule.startDate) ||
            selectedDate.isAtSameMomentAs(schedule.endDate) ||
            (selectedDate.isAfter(schedule.startDate) &&
              selectedDate.isBefore(schedule.endDate))) &&
          uniqueScheduleIds.add(schedule.id))
        .toList();

    if (relatedSchedules.isNotEmpty) {
      // 일정이 있는 날짜를 클릭했을 때 다이얼로그 표시
      final result = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('일정 생성 및 수정 선택'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: relatedSchedules.map((schedule) {
                  return ListTile(
                    title: Text(schedule.title),
                    subtitle: Text('${schedule.owner.name}'),
                    trailing: Text(
                      '${schedule.startTime != null ?
                      DateFormat('HH:mm').format(DateTime(2024, 1, 1, schedule.startTime!.hour, schedule.startTime!.minute)) :
                      '시작 시간 없음'} - '
                          '${schedule.endTime != null ?
                      DateFormat('HH:mm').format(DateTime(2024, 1, 1, schedule.endTime!.hour, schedule.endTime!.minute)) :
                      '종료 시간 없음'}',
                    ),
                    onTap: schedule.owner.name == userName
                        ? () async {
                      final modifyResult = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScheduleModifyPage(
                            schedule: schedule,
                            selectedDate: selectedDate,
                          ),
                        ),
                      );

                      if (modifyResult != null) {
                        if (modifyResult is Schedule) {
                          _updateEvent(modifyResult);
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                        } else if (modifyResult == 'delete') {
                          setState(() {
                            events.forEach((date, schedules) {
                              schedules.removeWhere((s) => s.id == schedule.id);
                            });
                            events.removeWhere((date, schedules) => schedules.isEmpty);
                            scheduleCount--;
                          });

                          _deleteEvent(schedule.startDate, schedule.id);
                          _saveEvents();
                          Navigator.of(context).pop(); // 다이얼로그 닫기
                        }
                      }
                    }
                        : null, // 사용자가 소유하지 않은 일정은 클릭 불가
                  );
                }).toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('새 일정 생성'),
                onPressed: () async {
                  // 새 일정 생성 페이지로 이동
                  final createResult = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ScheduleCreatePage(
                        selectedDate: selectedDate,
                        owner: OwnerInfo(name: userName, color: userColor),
                      ),
                    ),
                  );

                  if (createResult != null && createResult is Schedule) {
                    _addEvent(selectedDate, createResult);
                    // 다이얼로그 닫기
                    Navigator.of(context).pop();
                  }
                },
              ),
              TextButton(
                child: Text('닫기'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      // 일정이 없는 날짜의 기존 로직
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleCreatePage(
            selectedDate: selectedDate,
            owner: OwnerInfo(name: userName, color: userColor),
          ),
        ),
      );

      if (result != null && result is Schedule) {
        _addEvent(selectedDate, result);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefs,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }


          return Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  if (!isLoading)
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(Icons.chevron_left, color: Colors.green),
                                onPressed: () => _changeMonth(-1),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _showYearMonthPicker = true),
                                child: Text(
                                  DateFormat('yyyy년 MM월').format(_focusedDay),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.chevron_right, color: Colors.green),
                                onPressed: () => _changeMonth(1),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Table(
                            children: [
                              TableRow(
                                children: ['일', '월', '화', '수', '목', '금', '토'].map((day) => Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: day == '일' ? Colors.red : (day == '토' ? Colors.blue : Colors.black),
                                    ),
                                  ),
                                )).toList(),
                              ),
                              ..._buildCalendarRows(),
                            ],
                          ),
                        ),
                        BottomIcons(),
                      ],
                    ),

                  if (_showYearMonthPicker)
                    Positioned.fill(
                      child: YearMonthPicker(
                        initialDate: _focusedDay,
                        onSelect: (year, month) async {
                          setState(() {
                            _focusedDay = DateTime(year, month, 1);
                            _showYearMonthPicker = false;
                            isLoading = true; // 로딩 시작
                          });
                          await _loadEvents(); // 선택한 달의 데이터를 로드
                          setState(() {
                            isLoading = false; // 로딩 종료
                          });
                        },
                        onClose: () => setState(() => _showYearMonthPicker = false),
                      ),
                    ),

                  // 로딩 오버레이 (isLoading이 true일 때만 표시)
                  if (isLoading)
                    Container(
                      color: Colors.black.withOpacity(0.5), // 반투명 배경
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // 흰색 스피너
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

}

class YearMonthPicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(int, int) onSelect;
  final VoidCallback onClose;

  YearMonthPicker({
    required this.initialDate,
    required this.onSelect,
    required this.onClose,
  });

  @override
  _YearMonthPickerState createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<YearMonthPicker> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 300,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    onPressed: () => setState(() => _year--),
                  ),
                  Text(
                    '$_year년',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    onPressed: () => setState(() => _year++),
                  ),
                ],
              ),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 2,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _month == index + 1 ? Colors.green : Colors.white,
                      foregroundColor: _month == index + 1 ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => _month = index + 1),
                    child: Text('${index + 1}월'),
                  );
                },
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onClose,
                    child: Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () => widget.onSelect(_year, _month),
                    child: Text('확인'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}