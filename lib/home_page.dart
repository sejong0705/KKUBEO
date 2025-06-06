import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kkubeo/widgets/routine_add_page.dart';
import 'package:kkubeo/splash_screen.dart';
import 'package:kkubeo/theme_provider.dart';
import 'package:kkubeo/widgets/chat_page.dart';
import 'package:kkubeo/widgets/today_routine_list.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? nickname;
  List<String> todayRoutines = [];
  List<String> completedRoutines = [];

  @override
  void initState() {
    super.initState();
    _loadNickname();
    _loadTodayRoutines();
    _loadCompletedRoutines();
  }

  Future<void> _loadNickname() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nickname = prefs.getString('nickname') ?? '닉네임 없음';
    });
  }

  Future<void> _loadTodayRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final String today =
    ['월', '화', '수', '목', '금', '토', '일'][DateTime.now().weekday - 1];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('routines')
        .get();

    final routines = snapshot.docs
        .where((doc) {
      final data = doc.data();
      final days = data['repeatDays'] as List<dynamic>?;
      return days?.map((e) => e.toString()).contains(today) ?? false;
    })
        .map((doc) => doc['title'] as String)
        .toList();

    setState(() {
      todayRoutines = routines;
    });
  }

  Future<void> _loadCompletedRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('checkLog')
        .doc(todayStr)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final completed = <String>[];

    for (var entry in data.entries) {
      final value = entry.value;
      if (value is Map && value['completed'] == true) {
        completed.add(entry.key);
      }
    }

    setState(() {
      completedRoutines = completed;
    });
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final total = todayRoutines.length;
    final done = completedRoutines.length;
    final percent = total == 0 ? 0.0 : done / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KKUBEO'),
        actions: [
          Switch(
            value: isDark,
            onChanged: (val) => themeProvider.toggleTheme(val),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularPercentIndicator(
              radius: 80.0,
              lineWidth: 15.0,
              percent: percent.clamp(0.0, 1.0),
              center: Text(
                "${(percent * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              progressColor: Colors.deepOrange,
              backgroundColor: Colors.grey.shade300,
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
            const SizedBox(height: 16),
            Text(
              nickname == null ? '닉네임 불러오는 중...' : '환영합니다, $nickname 님!',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 24),
            TodayRoutineList(
              routines: todayRoutines,
              onChanged: (updatedCompleted) {
                setState(() {
                  completedRoutines = updatedCompleted;
                });
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoutineAddPage()),
                );

                if (result == true) {
                  await _loadTodayRoutines();
                  await _loadCompletedRoutines();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("루틴 추가"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatPage()),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }
}