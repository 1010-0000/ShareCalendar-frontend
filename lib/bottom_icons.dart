import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'alarm_settings_page.dart';  // 추가: AlarmSettingsPage 임포트

class BottomIcons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(FontAwesomeIcons.atom, color: Colors.green),
          Icon(FontAwesomeIcons.calendarCheck, color: Colors.green),
          GestureDetector(
            onTap: () {
              // 아이콘 클릭 시 AlarmSettingsPage로 이동
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AlarmSettingsPage()),
              );
            },
            child: Icon(Icons.person, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
