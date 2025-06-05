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

    final checkLogRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('checkLog');

    final snapshot = await checkLogRef.get();

    final Map<DateTime, double> result = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      int total = 0;
      int completed = 0;

      for (var entry in data.entries) {
        final value = entry.value;
        if (value is Map && value.containsKey('completed')) {
          total++;
          if (value['completed'] == true) completed++;
        }
      }

      if (total == 0) continue; // 루틴이 하나도 없던 날은 건너뜀

      final date = DateTime.tryParse(doc.id); // 날짜 포맷 체크
      if (date != null) {
        result[date] = completed / total;
      }
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
