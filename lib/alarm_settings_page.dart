import 'package:flutter/material.dart';
import 'bottom_icons.dart';
import 'calendar_page.dart';  // 추가: CalendarPage 임포트

class AlarmSettingsPage extends StatefulWidget {
  @override
  _AlarmSettingsPageState createState() => _AlarmSettingsPageState();
}

class _AlarmSettingsPageState extends State<AlarmSettingsPage> {
  bool allNotifications = true;
  bool userJoinNotifications = true;
  bool calendarNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with shadow, centered text, and margin-top
            Container(
              margin: EdgeInsets.only(top: 36), // Added margin-top
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () {
                      // 뒤로가기 버튼 클릭 시 캘린더 페이지로 이동
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => CalendarPage()),
                      );
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '알림 설정',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48), // Add a SizedBox to balance the layout
                ],
              ),
            ),

            // Add SizedBox to increase space between header and settings
            SizedBox(height: 20),

            // Settings List
            Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildSwitchTile('전체 알림', allNotifications, onChanged: (value) {
                    setState(() {
                      allNotifications = value;
                    });
                  }),
                  SizedBox(height: 34),
                  _buildSwitchTile('사용자 가입 알림', userJoinNotifications, onChanged: (value) {
                    setState(() {
                      userJoinNotifications = value;
                    });
                  }),
                  SizedBox(height: 34),
                  _buildSwitchTile(
                    '캘린더 알림',
                    calendarNotifications,
                    subtitle: '일정 등록/수정/삭제',
                    onChanged: (value) {
                      setState(() {
                        calendarNotifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            Spacer(),

            // Bottom Navigation
            BottomIcons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, {String? subtitle, required Function(bool) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.blue[200],
              activeTrackColor: Colors.blue[100],
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
