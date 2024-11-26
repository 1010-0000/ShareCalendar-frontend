import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'bottom_icons.dart';
class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late DateTime selectedDate;
  late List<DateTime> weekDays;
  final dateFormat = DateFormat('M월 d일', 'ko_KR');
  final loggedInUser = '희찬';
  final otherUsers = ['선준', '건우', '문권', '희찬'];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _generateWeekDays();
  }

  void _generateWeekDays() {
    DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
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
        child: Column(
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
                      ...schedules
                          .where((schedule) =>
                      schedule['date'].toString().substring(0, 10) ==
                          selectedDate.toString().substring(0, 10))
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
                                    schedule['title'].toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        schedule['time'].toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        schedule['owner'].toString(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: schedule['owner'] == loggedInUser
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
                      ))
                          .toList(),

                      if (schedules
                          .where((schedule) =>
                      schedule['date'].toString().substring(0, 10) ==
                          selectedDate.toString().substring(0, 10))
                          .isEmpty)
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
      ),
    );
  }
}

