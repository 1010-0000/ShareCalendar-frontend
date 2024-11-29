import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'bottom_icons.dart';
import 'schedule_creation_page.dart';
import 'schedule_modify_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'services/firebaseService.dart';

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
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final userAndFriends = await _firebaseService.fetchUserAndFriends();
      final yearMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final filteredUsers = await _firebaseService.filterUsersInCalendar(userAndFriends, yearMonth);
      final tasks = await _firebaseService.fetchTasksForFilteredUsers(filteredUsers, DateTime.now());
      print("tasks 데이터: $tasks");
    } catch (e) {
      print("오류 발생: $e");
    }
  }

  Future<void> _loadEvents() async {
    try {
      final prefs = await _prefs;
      final String? eventsJson = prefs.getString(EVENTS_STORAGE_KEY);

      if (eventsJson != null) {
        final Map<String, dynamic> decodedData = json.decode(eventsJson);

        setState(() {
          events = {};
          decodedData.forEach((key, value) {
            final DateTime date = DateTime.parse(key);
            final List<dynamic> scheduleList = value as List<dynamic>;

            events[date] = scheduleList.map((scheduleData) {
              return Schedule(
                id: scheduleData['id'],
                title: scheduleData['title'],
                startDate: DateTime.parse(scheduleData['startDate']),
                startTime: scheduleData['startTime'] != null
                    ? TimeOfDay(
                    hour: scheduleData['startTime']['hour'],
                    minute: scheduleData['startTime']['minute']
                )
                    : null,
                endDate: DateTime.parse(scheduleData['endDate']),
                endTime: scheduleData['endTime'] != null
                    ? TimeOfDay(
                    hour: scheduleData['endTime']['hour'],
                    minute: scheduleData['endTime']['minute']
                )
                    : null,
                memo: scheduleData['memo'],
                owner: OwnerInfo(
                  name: scheduleData['owner']['name'],
                  color: Color(scheduleData['owner']['color']),
                ),
              );
            }).toList();
          });

          scheduleCount = events.values.fold(0, (sum, list) => sum + list.length);
        });
      }
    } catch (e) {
      print('Error loading events: $e');
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

  void _addEvent(DateTime date, Schedule schedule) {
    setState(() {
      if (events[date] == null) {
        events[date] = [schedule];
      } else {
        events[date]!.add(schedule);
      }
      scheduleCount++;
    });
    _saveEvents();
  }

  void _updateEvent(DateTime date, Schedule updatedSchedule) {
    setState(() {
      if (events[date] != null) {
        int index = events[date]!.indexWhere((schedule) => schedule.id == updatedSchedule.id);
        if (index != -1) {
          events[date]![index] = updatedSchedule;
        }
      }
    });
    _saveEvents();
  }

  void _deleteEvent(DateTime date, String scheduleId) {
    setState(() {
      if (events[date] != null) {
        events[date]!.removeWhere((schedule) => schedule.id == scheduleId);
        if (events[date]!.isEmpty) {
          events.remove(date);
        }
      }
    });
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
    Map<String, Schedule> displayedEvents = {};

    events.entries.forEach((entry) {
      entry.value.forEach((schedule) {
        if (currentDate.isAtSameMomentAs(schedule.startDate) ||
            currentDate.isAtSameMomentAs(schedule.endDate) ||
            (currentDate.isAfter(schedule.startDate) &&
                currentDate.isBefore(schedule.endDate))) {
          if (!displayedEvents.containsKey(schedule.id)) {
            displayedEvents[schedule.id] = schedule;
          }
        }
      });
    });

    displayedEvents.values.forEach((schedule) {
      bool isStart = currentDate.isAtSameMomentAs(schedule.startDate);
      bool isEnd = currentDate.isAtSameMomentAs(schedule.endDate);
      bool isMiddle = currentDate.isAtSameMomentAs(schedule.middleDate);

      eventWidgets.add(
        Container(
          height: 24,
          decoration: BoxDecoration(
            color: schedule.owner.color.withOpacity(0.2),
            border: Border(
              left: isStart ? BorderSide.none : BorderSide(width: 0.5, color: schedule.owner.color.withOpacity(0.2)),
              right: isEnd ? BorderSide.none : BorderSide(width: 0.5, color: schedule.owner.color.withOpacity(0.2)),
            ),
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
    });

    return eventWidgets;
  }

  void _navigateToSchedulePage(DateTime selectedDate) async {
    // 선택한 날짜가 포함된 모든 일정 찾기
    List<Schedule> relatedSchedules = events.values
        .expand((schedules) => schedules)
        .where((schedule) =>
    (selectedDate.isAtSameMomentAs(schedule.startDate) ||
        selectedDate.isAtSameMomentAs(schedule.endDate) ||
        (selectedDate.isAfter(schedule.startDate) &&
            selectedDate.isBefore(schedule.endDate))))
        .toList();

    if (relatedSchedules.isNotEmpty) {
      // 관련 일정이 있다면 첫 번째 일정으로 수정 페이지 열기
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleModifyPage(
            schedule: relatedSchedules[0],
            selectedDate: selectedDate,
          ),
        ),
      );

      if (result != null) {
        if (result is Schedule) {
          // 일정 수정 시 관련된 모든 날짜의 일정 업데이트
          events.forEach((date, schedules) {
            for (int i = 0; i < schedules.length; i++) {
              if (schedules[i].id == result.id) {
                events[date]![i] = result;
              }
            }
          });
          _saveEvents();
        } else if (result == 'delete') {
          setState(() {
            // 일정 삭제 시 관련된 모든 날짜의 일정 삭제
            events.removeWhere((date, schedules) =>
                schedules.any((schedule) => schedule.id == relatedSchedules[0].id));
            // 전체 스케줄 카운트 감소
            scheduleCount--;
          });
          // 삭제된 일정 저장
          _saveEvents();
        }
      }
    } else {
      // 관련 일정이 없으면 새 일정 생성
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

