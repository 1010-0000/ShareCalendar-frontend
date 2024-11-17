import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendar_page.dart';

class ScheduleModifyPage extends StatefulWidget {
  final Schedule schedule;
  final DateTime selectedDate;

  ScheduleModifyPage({required this.schedule, required this.selectedDate});

  @override
  _ScheduleModifyPageState createState() => _ScheduleModifyPageState();
}

class _ScheduleModifyPageState extends State<ScheduleModifyPage> {
  late TextEditingController _titleController;
  late TextEditingController _memoController;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _memoFocusNode = FocusNode();

  late DateTime _startDate;
  late TimeOfDay? _startTime;
  late DateTime _endDate;
  late TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule.title);
    _memoController = TextEditingController(text: widget.schedule.memo);
    _startDate = widget.schedule.startDate;
    _startTime = widget.schedule.startTime;
    _endDate = widget.schedule.endDate;
    _endTime = widget.schedule.endTime;
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    _titleFocusNode.unfocus();
    _memoFocusNode.unfocus();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: Locale('ko'),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    _titleFocusNode.unfocus();
    _memoFocusNode.unfocus();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime ?? TimeOfDay.now() : _endTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        if (isStart) {
          _startTime = pickedTime;
        } else {
          _endTime = pickedTime;
        }
      });
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일').format(date);
  }

  void _deleteSchedule() {
    Navigator.pop(context, 'delete');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _titleFocusNode.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with shadow, centered text, and margin-top
            Container(
              margin: EdgeInsets.only(top: 0), // Added margin-top
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
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        '일정 수정하기',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48), // Balances the layout
                ],
              ),
            ),

            SizedBox(height: 20),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('제목', style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      decoration: InputDecoration(
                        hintText: '제목을 입력하세요.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.arrow_right, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('시작 날짜'),
                        Spacer(),
                        GestureDetector(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              formatDate(_startDate),
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('시작 시간'),
                        Spacer(),
                        GestureDetector(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _startTime != null
                                  ? _startTime!.format(context)
                                  : '시작 시간을 선택하세요',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(Icons.arrow_left, color: Colors.red),
                        SizedBox(width: 10),
                        Text('종료 날짜'),
                        Spacer(),
                        GestureDetector(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              formatDate(_endDate),
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.red),
                        SizedBox(width: 10),
                        Text('종료 시간'),
                        Spacer(),
                        GestureDetector(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _endTime != null
                                  ? _endTime!.format(context)
                                  : '종료 시간을 선택하세요',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text('메모', style: TextStyle(fontSize: 16)),
                    TextField(
                      controller: _memoController,
                      focusNode: _memoFocusNode,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '메모를 입력하세요.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (_titleController.text.isNotEmpty) {
                                final updatedSchedule = Schedule(
                                  id: widget.schedule.id,
                                  title: _titleController.text,
                                  startDate: _startDate,
                                  startTime: _startTime,
                                  endDate: _endDate,
                                  endTime: _endTime,
                                  memo: _memoController.text,
                                );
                                Navigator.pop(context, updatedSchedule);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('제목을 입력해주세요.')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreenAccent,
                              minimumSize: Size(160, 50),
                            ),
                            child: Text(
                              '일정을 수정할게요',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _deleteSchedule,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              minimumSize: Size(160, 50),
                            ),
                            child: Text(
                              '일정 삭제하기',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
