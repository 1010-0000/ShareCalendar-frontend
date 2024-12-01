import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomIcons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // 메인 페이지로 이동
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (ModalRoute.of(context)?.settings.name != '/mainPage') {
                  Navigator.pushNamed(context, '/mainPage');
                }
              },
              child: Center(
                child: Icon(
                  FontAwesomeIcons.atom,
                  color: ModalRoute.of(context)?.settings.name == '/mainPage'
                      ? Colors.grey
                      : Colors.green,
                ),
              ),
            ),
          ),
          // 캘린더 페이지로 이동
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (ModalRoute.of(context)?.settings.name != '/calendar') {
                  Navigator.pushNamed(context, '/calendar');
                }
              },
              child: Center(
                child: Icon(
                  FontAwesomeIcons.calendarCheck,
                  color: ModalRoute.of(context)?.settings.name == '/calendar'
                      ? Colors.grey
                      : Colors.green,
                ),
              ),
            ),
          ),
          // 마이페이지로 이동
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (ModalRoute.of(context)?.settings.name != '/profile') {
                  Navigator.pushNamed(context, '/profile');
                }
              },
              child: Center(
                child: Icon(
                  Icons.person,
                  color: ModalRoute.of(context)?.settings.name == '/profile'
                      ? Colors.grey
                      : Colors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
