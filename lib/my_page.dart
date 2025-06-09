import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kkubeo/widgets/routine_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kkubeo/widgets/cheer_messages.dart';
class MyPage extends StatefulWidget {
  final VoidCallback? onRoutineChanged;
  const MyPage({super.key, this.onRoutineChanged});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String nickname = '';
  List<Map<String, dynamic>> routines = [];
  String? cheer;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadCheerMessage();
  }
  Future<void> _loadCheerMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10); // yyyy-MM-dd
    final savedDate = prefs.getString('cheerDate');
    final savedMessage = prefs.getString('cheerMessage');

    if (savedDate == today && savedMessage != null) {
      setState(() {
        cheer = savedMessage;
      });
    } else {
      final random = Random();
      final newMessage = cheerMessages[random.nextInt(cheerMessages.length)];
      await prefs.setString('cheerDate', today);
      await prefs.setString('cheerMessage', newMessage);
      setState(() {
        cheer = newMessage;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        nickname = data['nickname'] ?? '';
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('routines')
          .get();

      final loaded = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'],
          'repeatDays': doc['repeatDays'],
        };
      }).toList();

      setState(() {
        routines = loaded;
      });
    }
  }

  Future<void> _deleteRoutine(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final routineRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('routines')
        .doc(routineId);

    final routineDoc = await routineRef.get();
    final title = routineDoc.data()?['title']; // ✅ title 가져오기

    // 1. 루틴 삭제
    await routineRef.delete();

    // 2. 오늘 날짜 checkLog에서 해당 루틴 필드 삭제
    if (title != null && title is String) {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final checkLogRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('checkLog')
          .doc(todayStr);

      // title 필드 삭제 시도
      await checkLogRef.update({title: FieldValue.delete()}).catchError((e) {
        // 해당 필드가 없을 수 있으니 무시
      });
    }

    // 3. 로컬 상태 갱신
    setState(() {
      routines.removeWhere((routine) => routine['id'] == routineId);
    });

    // 4. 홈 화면 리프레시 콜백 호출
    widget.onRoutineChanged?.call();
  }

  Future<void> _updateSingleRoutine(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('routines')
        .doc(routineId)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      final index = routines.indexWhere((r) => r['id'] == routineId);
      if (index != -1) {
        routines[index] = {
          'id': routineId,
          'title': data['title'],
          'repeatDays': data['repeatDays'],
        };
      }
    });
  }

  Future<void> _cleanUpCheckLogIfRepeatDayChanged({
    required String userId,
    required String routineTitle,
    required List<String> oldDays,
    required List<String> newDays,
  }) async {
    final now = DateTime.now();
    final todayWeekday = ['월', '화', '수', '목', '금', '토', '일'][now.weekday - 1];

    if (oldDays.contains(todayWeekday) && !newDays.contains(todayWeekday)) {
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final checkLogRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('checkLog')
          .doc(todayStr);

      await checkLogRef.update({
        routineTitle: FieldValue.delete(),
      }).catchError((e) {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 응원 메시지
            if (cheer != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📣", style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueAccent, width: 1),
                      ),
                      child: Text(
                        cheer!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              const CircularProgressIndicator(), // 로딩 중 표
            const SizedBox(height: 20),
            Text('$nickname 루틴 리스트', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated( //리스트를 반복적으로 보여줌 separated: 항목 사이에 위젯 추가 가능
                itemCount: routines.length, // 루틴 길이만큼
                separatorBuilder: (context, index) => const Divider( //항목별 구분선
                  thickness: 1,
                  height: 1,
                  color: Colors.grey,
                ),
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  return Dismissible( // 스와이프 가능 위젯
                    key: Key(routine['id']),
                    direction: DismissDirection.endToStart, // 오른쪽 -> 왼쪽
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete_sweep, color: Colors.white,size: 30,),
                    ),
                    onDismissed: (direction) {
                      _deleteRoutine(routine['id']);
                    },
                    child: ListTile(
                      leading: const Icon(
                        Icons.edit,
                        size: 35,
                        color: Colors.deepOrange,
                      ),
                      title: Text(routine['title']),
                      subtitle: Text("반복 요일: ${(routine['repeatDays'] as List).join(', ')}"),
                      onTap: () async {
                        // 루틴 편집 전 기존 반복 요일을 저장 (checkLog 정리 비교용)
                        final oldRepeatDays = List<String>.from(routine['repeatDays']);
                        // 루틴 편집 페이지로 이동
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutineEditPage(routineId: routine['id']),
                          ),
                        );
                        // 루틴이 수정되었다면
                        if (updated == true) {
                          // 변경된 루틴 데이터를 다시 불러와 화면에 반영
                          await _updateSingleRoutine(routine['id']);

                          // 사용자 ID 불러오기
                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('user_id');
                          if (userId == null) return;

                          // 수정된 루틴 문서 가져오기 (새 repeatDays 확인용)
                          final doc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('routines')
                              .doc(routine['id'])
                              .get();
                          // 수정된 반복 요일 불러오기
                          final newRepeatDays = List<String>.from(doc.data()?['repeatDays'] ?? []);

                          // 오늘 날짜가 기존에는 포함되고, 수정 후에는 빠졌을 경우
                          // 오늘 날짜의 checkLog에서 해당 루틴 기록 제거
                          await _cleanUpCheckLogIfRepeatDayChanged(
                            userId: userId,
                            routineTitle: routine['title'],
                            oldDays: oldRepeatDays,
                            newDays: newRepeatDays,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


