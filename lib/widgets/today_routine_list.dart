import 'package:flutter/material.dart';
import 'package:kkubeo/widgets/timer_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class TodayRoutineList extends StatefulWidget {
  final List<String> routines;
  final void Function(List<String>) onChanged;
  final void Function()? onRoutineChanged;

  const TodayRoutineList({super.key,
    required this.onChanged,
    required this.routines,
    this.onRoutineChanged,
  });

  @override
  State<TodayRoutineList> createState() => _TodayRoutineListState();
}

class _TodayRoutineListState extends State<TodayRoutineList> {
  final ScrollController _scrollController = ScrollController();

  List<String> get routines => widget.routines;
  List<String> completed = [];
  Map<String, Duration> durations = {};

  @override
  void dispose() {
    _scrollController.dispose(); //메모리 누수 방지
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTodayCheckLog();
  }

  Future<void> _loadTodayCheckLog() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day
        .toString().padLeft(2, '0')}";

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('checkLog')
        .doc(todayStr)
        .get();

    if (!doc.exists) {
      widget.onChanged([]);
      return;
    }

    final data = doc.data()!;
    List<String> newCompleted = [];
    Map<String, Duration> newDurations = {};

    for (var entry in data.entries) {
      final title = entry.key;
      final value = entry.value;

      if (value is Map && value['completed'] == true) {
        newCompleted.add(title);
        if (value.containsKey('durationInSeconds')) {
          final seconds = value['durationInSeconds'];
          if (seconds is int && seconds > 0) {
            newDurations[title] = Duration(seconds: seconds);
          }
        }
      }
    }

    setState(() {
      completed = newCompleted;
      durations = newDurations;
    });

    widget.onChanged(newCompleted);
  }

  Future<void> _toggle(String title, bool isChecked) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day
        .toString().padLeft(2, '0')}";

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('checkLog')
        .doc(todayStr);

    await ref.set({
      title: {
        'completed': isChecked,
        'durationInSeconds': durations[title]?.inSeconds ?? 0,
      },
    }, SetOptions(merge: true));

    setState(() {
      if (isChecked) {
        if (!completed.contains(title)) {
          completed.add(title); // 중복 방지
        }
      } else {
        completed.remove(title);
      }
    });

    widget.onChanged(completed);
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;
    if (h > 0) return '$h시간 $m분 $s초';
    if (m > 0) return '$m분 $s초';
    return '$s초';
  }

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) {
      return const Center(child: Text("오늘 수행할 루틴이 없습니다."));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "오늘의 루틴",
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                shrinkWrap: true,
                controller: _scrollController,
                itemCount: routines.length,
                itemBuilder: (context, index) {
                  final routine = routines[index];
                  final isChecked = completed.contains(routine);
                  final duration = durations[routine];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isChecked) {
                                  completed.remove(routine);
                                } else {
                                  completed.add(routine);
                                }
                                _toggle(routine, !isChecked);
                              });
                              widget.onChanged(completed);
                            },
                            child: Icon(
                              isChecked ? Icons.check_box : Icons
                                  .check_box_outline_blank,
                              color: Colors.deepOrange,size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              routine,
                              style: const TextStyle(
                                color: Colors.black,
                                decoration: TextDecoration.none,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (duration != null)
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(color: Colors.black),
                            ),
                          IconButton(
                            icon: const Icon(
                                Icons.access_alarms, color: Colors.black,size: 25,),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      TimerPage(
                                        routineTitle: routine,
                                        initialDuration: duration,
                                      ),
                                ),
                              );
                              if (result != null && result is Duration) {
                                setState(() {
                                  durations[routine] = result;
                                });
                                _toggle(routine, completed.contains(routine));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
