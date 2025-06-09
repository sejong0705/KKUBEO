import 'package:flutter/material.dart';
import 'package:kkubeo/widgets/completed_routine_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String? userId; //SharedPreferences에서 받아옴
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  //선택한 날짜의 완료 루틴
  List<Map<String, dynamic>> completedRoutines = [];

  Map<DateTime, double> completionMap = {};


  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData();
  }

  Future<void> _loadUserIdAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    if (id == null) return; // 유저 정보 없으면 리턴

    setState(() {
      userId = id;
    });

    await fetchCompletionData(); // userId 설정 후 루틴 진행률 불러오기
  }
  Future<void> fetchCompletionData() async {
    if (userId == null) return;
    // 루틴 및 수행 기록 불러오기
    final routinesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId!)
        .collection('routines');

    final checkLogRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId!)
        .collection('checkLog');

    final routinesSnapshot = await routinesRef.get();
    final checkLogSnapshot = await checkLogRef.get();

    // 모든 루틴 정보 불러오기 (title + 반복요일)
    final allRoutines = routinesSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'title': data['title'],
        'repeatDays': List<String>.from(data['repeatDays'] ?? []),
      };
    }).toList();

    final Map<DateTime, double> result = {};
    // 각 날짜별로 수행률 계산
    for (var logDoc in checkLogSnapshot.docs) {
      final date = DateTime.tryParse(logDoc.id);
      if (date == null) continue;

      final logData = logDoc.data();

      final weekdayStr = ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];

      // 해당 날짜에 반복 요일이 일치하는 루틴 목록 필터링
      final todaysRoutines = allRoutines
          .where((r) => r['repeatDays'].contains(weekdayStr))
          .map((r) => r['title'] as String)
          .toList();

      if (todaysRoutines.isEmpty) continue;

      int total = todaysRoutines.length;
      int completedCount = 0;

      for (final routineTitle in todaysRoutines) {
        final routineLog = logData[routineTitle];
        if (routineLog is Map && routineLog['completed'] == true) {
          completedCount++;
        }
      }
      //날짜 별 퍼센트 저장
      result[date] = completedCount / total;
    }

    setState(() {
      completionMap = result;
    });
  }
  Future<List<Map<String, dynamic>>> fetchCompletedRoutinesByDate(
      DateTime selectedDay, String userId) async {
    final todayStr =
        "${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('checkLog')
        .doc(todayStr)
        .get();

    if (!doc.exists) return [];

    final data = doc.data()!;
    List<Map<String, dynamic>> result = [];

    for (var entry in data.entries) {
      final title = entry.key;
      final value = entry.value;

      if (value is Map && value['completed'] == true) {
        result.add({
          'title': title,
          'duration': value['durationInSeconds'] ?? 0,
        });
      }
    }

    return result;
  }

  Color getColorByPercentage(double percentage) {
    if (percentage < 0.1) return Colors.deepOrange[100]!;
    if (percentage < 0.25) return Colors.deepOrange[200]!;
    if (percentage < 0.5) return Colors.deepOrange[300]!;
    if (percentage < 0.75) return Colors.deepOrange[500]!;
    return Colors.deepOrange[700]!;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.deepOrange[100]!,
                      Colors.deepOrange[200]!,
                      Colors.deepOrange[300]!,
                      Colors.deepOrange[500]!,
                      Colors.deepOrange[700]!,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2001, 1, 1),
              lastDay: DateTime.utc(2099, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) async {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });

                if (userId != null) {
                  final completed = await fetchCompletedRoutinesByDate(selectedDay, userId!);
                  setState(() {
                    completedRoutines = completed;
                  });
                }
              },
              //2week 버튼 안보이게
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: '',
              },
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(fontSize: 16), //일반 날짜
                weekendTextStyle: TextStyle(fontSize: 16, color: Colors.red), //주말
                todayTextStyle: TextStyle(fontSize: 16), //오늘
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, _) {
                  final date = DateTime(day.year, day.month, day.day);
                  if (!completionMap.containsKey(date)) return null;

                  final percent = completionMap[date]!;
                  final bgColor = getColorByPercentage(percent);

                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                },
                todayBuilder: (context, day, _) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.limeAccent[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                },
              ),
            ),
            CompletedRoutineList(
              selectedDay: _selectedDay,
              completedRoutines: completedRoutines,
            ),
          ],
        ),
      ),
    );
  }
}
