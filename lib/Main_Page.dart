import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'bottom_icons.dart';
import 'services/firebaseService.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _tasksByUser = [];
  bool isLoading = true;
  late DateTime selectedDate;
  late List<DateTime> weekDays;
  final dateFormat = DateFormat('M월 d일', 'ko_KR');
  String userName = '';
  final otherUsers = ['선준', '건우', '문권', '희찬'];

  @override
  void initState() {
    super.initState();
    _initializeData();
    selectedDate = DateTime.now();
    _generateWeekDays();
  }

  Future<void> _initializeData() async {
    try {
      final userData = await _firebaseService.getUserNameEmail();
      setState(() {
        userName = userData['name'].toString();
        isLoading = false;
      });

      final userAndFriends = await _firebaseService.fetchUserAndFriends();
      final tasks = await _firebaseService.fetchTasksForFilteredUsers(
          userAndFriends, selectedDate);

      // 현재 선택된 날짜에 해당하는 일정만 필터링
      final filteredTasks = tasks.where((task) {
        final startDate = DateTime.parse(task["startDate"]);
        final endDate = DateTime.parse(task["endDate"]);

        return selectedDate.isAtSameMomentAs(startDate) ||
            selectedDate.isAtSameMomentAs(endDate) ||
            (selectedDate.isAfter(startDate) &&
                selectedDate.isBefore(endDate)) ||
            (selectedDate.year == startDate.year &&
                selectedDate.month == startDate.month &&
                selectedDate.day == startDate.day) ||
            (selectedDate.year == endDate.year &&
                selectedDate.month == endDate.month &&
                selectedDate.day == endDate.day);
      }).toList();

      setState(() {
        _tasksByUser = filteredTasks;
        isLoading = false;
      });
    } catch (e) {
      print('오류 발생: $e');
      setState(() {
        userName = "오류";
        isLoading = false;
      });
    }
  }

  void _generateWeekDays() {
    DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = dateFormat.format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FFF0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Welcome Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 30,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Date Card with Scrollable Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentDate,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                    _initializeData();
                                  },
                                  child: CircleAvatar(
                                    radius: 24,
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
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '오늘의 일정',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Tasks List
                              if (_tasksByUser.isNotEmpty)
                                Column(
                                  children: _tasksByUser
                                      .map((schedule) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Colors.green,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                schedule['title'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text(
                                                    schedule['name'],
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: schedule['isUser'] == true
                                                          ? Colors.green
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${schedule['startTime']} - ${schedule['endTime']}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
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
                                ),
                              if (_tasksByUser.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    '일정 없음',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: BottomIcons(),
                ),
              ],
            ),

            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
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