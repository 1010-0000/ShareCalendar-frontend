import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late DateTime selectedDate;
  late List<DateTime> weekDays;
  final dateFormat = DateFormat('M월 d일', 'ko_KR'); // 한국어 로케일 추가

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now(); // 현재 날짜로 초기화
    _generateWeekDays();
  }

  void _generateWeekDays() {
    // 현재 날짜가 있는 주의 시작일(일요일)을 찾습니다
    DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = dateFormat.format(selectedDate); // 현재 날짜 포맷팅

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
                      const Text(
                        '이희찬님',
                        style: TextStyle(
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
                        currentDate,  // 포맷된 현재 날짜 사용
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '오늘 계획은 잠자기입니다.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),

                      // Week Calendar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: weekDays.map((date) => GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedDate = date;
                              _generateWeekDays(); // 주간 날짜 업데이트
                            });
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor:
                            date.year == selectedDate.year &&
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
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(FontAwesomeIcons.atom, color: Colors.green, size: 24),
                      SizedBox(height: 4),
                      Text('메인화면', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/calendar');
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(FontAwesomeIcons.calendarCheck, color: Colors.green, size: 24),
                        SizedBox(height: 4),
                        Text('캘린더', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/mypage');
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.person, color: Colors.green, size: 24),
                        SizedBox(height: 4),
                        Text('마이페이지', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}