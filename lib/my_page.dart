import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kkubeo/widgets/routine_edit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyPage extends StatefulWidget {
  final VoidCallback? onRoutineChanged;
  const MyPage({super.key, this.onRoutineChanged});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String nickname = '';
  List<Map<String, dynamic>> routines = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
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
        // 필드가 없을 수도 있으니 무시
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
          children: [
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
                        //수정 전 반복 요일을 먼저 저장
                        final oldRepeatDays = List<String>.from(routine['repeatDays']);
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoutineEditPage(routineId: routine['id']),
                          ),
                        );

                        if (updated == true) {
                          await _updateSingleRoutine(routine['id']);

                          final prefs = await SharedPreferences.getInstance();
                          final userId = prefs.getString('user_id');
                          if (userId == null) return;

                          // 🔽 루틴 수정 후 최신 데이터 가져오기
                          final doc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('routines')
                              .doc(routine['id'])
                              .get();

                          final newRepeatDays = List<String>.from(doc.data()?['repeatDays'] ?? []);

                          // 🔥 체크로그 정리 함수 호출
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


