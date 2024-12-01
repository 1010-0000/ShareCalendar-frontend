import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_icons.dart';
import 'schedule_creation_page.dart';
import 'schedule_modify_page.dart';
import 'services/firebaseService.dart';
import 'package:uuid/uuid.dart';

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
  bool isLoading = true;
  final FirebaseService _firebaseService = FirebaseService();
  // DateTime _focusedDay = DateTime.now().subtract(Duration(days: 4));
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _showYearMonthPicker = false;
  Map<DateTime, List<Schedule>> events = {};
  int scheduleCount = 0;
  static const String EVENTS_STORAGE_KEY = 'calendar_events';

  final List<OwnerInfo> owners = [
    OwnerInfo(name: '문권', color: Colors.purple),
    OwnerInfo(name: '선준', color: Colors.red),
  ];

  late Future<SharedPreferences> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = SharedPreferences.getInstance();
    _loadEvents();
    // _initializeData();
  }

  Future<List<Map<String, dynamic>>> _initializeData() async {
    try {
      final userAndFriends = await _firebaseService.fetchUserAndFriends();
      // print("$userAndFriends");

      final yearMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final filteredUsers = await _firebaseService.filterUsersInCalendar(userAndFriends, yearMonth);

      final tasks = await _firebaseService.fetchTasksForFilteredUsers(filteredUsers, DateTime.now());

      // print("tasks 데이터: $tasks");
      return tasks;
    } catch (e) {
      print("오류 발생: $e");
      return [];
    }
  }

  Future<void> _loadEvents() async {
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
              color: task["isUser"] ? Colors.green : Colors.blue,
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
        // print("$events");
      });
    } catch (e) {
      print('Error loading tasks: $e');
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

  OwnerInfo getNextOwner() {
    return owners[scheduleCount % owners.length];
  }

  void _changeMonth(int delta) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + delta, 1);
    });
  }

  void _addEvent(DateTime date, Schedule schedule) async {
    setState(() {
      if (events[date] == null) {
        events[date] = [schedule];
      } else {
        events[date]!.add(schedule);
      }
      scheduleCount++;
    });

    // Firebase에 저장
    await _firebaseService.saveTaskToFirebase(schedule);
    _saveEvents();
  }

  void _updateEvent(Schedule updatedSchedule) async {
    setState(() {
      // 기존 일정을 모든 날짜에서 완전히 제거
      events.forEach((date, schedules) {
        schedules.removeWhere((schedule) => schedule.id == updatedSchedule.id);
      });

      // 빈 리스트를 가진 날짜 제거
      events.removeWhere((date, schedules) => schedules.isEmpty);

      // 새로운 날짜 범위에 일정 추가 (중복 없이)
      int daysDifference = updatedSchedule.endDate.difference(updatedSchedule.startDate).inDays;
      for (int i = 0; i <= daysDifference; i++) {
        DateTime currentDate = updatedSchedule.startDate.add(Duration(days: i));

        // 이미 해당 날짜에 동일한 일정이 없는 경우에만 추가
        if (events[currentDate] == null) {
          events[currentDate] = [updatedSchedule];
        } else if (!events[currentDate]!.any((schedule) => schedule.id == updatedSchedule.id)) {
          events[currentDate]!.add(updatedSchedule);
        }
      }
    });

    // Firebase에 업데이트
    await _firebaseService.updateTaskInFirebase(updatedSchedule);

    _saveEvents();
  }

  // void _deleteEvent(DateTime date, String scheduleId) {
  //   setState(() {
  //     if (events[date] != null) {
  //       events[date]!.removeWhere((schedule) => schedule.id == scheduleId);
  //       if (events[date]!.isEmpty) {
  //         events.remove(date);
  //       }
  //     }
  //   });
  //   _saveEvents();
  // }

  void _deleteEvent(DateTime date, String scheduleId) async {
    setState(() {
      if (events[date] != null) {
        // Local state에서 이벤트 제거
        events[date]!.removeWhere((schedule) => schedule.id == scheduleId);
        if (events[date]!.isEmpty) {
          events.remove(date);
        }
      }
    });

    // Firebase에서 이벤트 삭제
    await _firebaseService.deleteTaskFromFirebase(scheduleId, date);

    // 로컬 저장소 동기화
    _saveEvents();
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
    Set<String> displayedEventIds = {}; // Set을 사용하여 중복 제거

    events.forEach((date, scheduleList) {
      for (var schedule in scheduleList) {
        // 현재 날짜가 일정의 기간에 포함되는지 확인
        // bool isInSchedulePeriod =
        //     currentDate.isAtSameMomentAs(schedule.startDate) ||
        //         currentDate.isAtSameMomentAs(schedule.endDate) ||
        //         (currentDate.isAfter(schedule.startDate) &&
        //             currentDate.isBefore(schedule.endDate));

        bool isInSchedulePeriod =
            (currentDate.year == schedule.startDate.year &&
                currentDate.month == schedule.startDate.month &&
                currentDate.day == schedule.startDate.day) ||
                (currentDate.year == schedule.endDate.year &&
                    currentDate.month == schedule.endDate.month &&
                    currentDate.day == schedule.endDate.day) ||
                (currentDate.isAfter(DateTime(schedule.startDate.year, schedule.startDate.month, schedule.startDate.day)) &&
                    currentDate.isBefore(DateTime(schedule.endDate.year, schedule.endDate.month, schedule.endDate.day)));

        // 이미 추가되지 않은 일정인 경우에만 추가
        if (isInSchedulePeriod && !displayedEventIds.contains(schedule.id)) {
          displayedEventIds.add(schedule.id);

          bool isStart = currentDate.isAtSameMomentAs(schedule.startDate);
          bool isEnd = currentDate.isAtSameMomentAs(schedule.endDate);
          bool isMiddle = currentDate.year == schedule.middleDate.year &&
              currentDate.month == schedule.middleDate.month &&
              currentDate.day == schedule.middleDate.day;

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
                  schedule.owner.name,
                  style: TextStyle(
                    color: schedule.owner.color,
                    fontSize: 12,
                  ),
                ),
              )
                  : null,
            ),
          );
        }
      }
    });

    // 기존의 2개 초과 이벤트 처리 로직 유지
    int totalEvents = displayedEventIds.length;
    if (totalEvents > 2) {
      // 기존 로직 그대로 유지
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
                    onTap: () async {
                      // 개별 일정 수정 기능 추가
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
                          // 다이얼로그 닫기
                          Navigator.of(context).pop();
                        } else if (modifyResult == 'delete') {
                          setState(() {
                            events.forEach((date, schedules) {
                              schedules.removeWhere((s) => s.id == schedule.id);
                            });

                            // 비어있는 날짜 제거
                            events.removeWhere((date, schedules) => schedules.isEmpty);

                            scheduleCount--;
                          });

                          // Firebase에서 일정 삭제
                          _deleteEvent(schedule.startDate, schedule.id); // Firebase 연동

                          _saveEvents();
                          // 다이얼로그 닫기
                          Navigator.of(context).pop();
                        }
                      }
                    },
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
                        owner: getNextOwner(),
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
            owner: getNextOwner(),
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
                                    color: Colors.green
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
                        onSelect: (year, month) {
                          setState(() {
                            _focusedDay = DateTime(year, month, 1);
                            _showYearMonthPicker = false;
                          });
                        },
                        onClose: () => setState(() => _showYearMonthPicker = false),
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
                  Text('$_year년', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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