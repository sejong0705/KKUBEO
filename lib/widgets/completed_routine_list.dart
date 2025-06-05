import 'package:flutter/material.dart';

class CompletedRoutineList extends StatelessWidget {
  final DateTime? selectedDay;
  final List<Map<String, dynamic>> completedRoutines; // 제목 + 시간

  const CompletedRoutineList({
    super.key,
    required this.selectedDay,
    required this.completedRoutines,
  });

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final h = duration.inHours;
    final m = duration.inMinutes % 60;
    final s = duration.inSeconds % 60;

    if (h > 0) return '$h시간 $m분 $s초';
    if (m > 0) return '$m분 $s초';
    return '$s초';
  }

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            "${selectedDay!.year}-${selectedDay!.month.toString().padLeft(2, '0')}-${selectedDay!.day.toString().padLeft(2, '0')} 완료 루틴",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (completedRoutines.isEmpty)
            const Text("완료한 루틴이 없습니다.", style: TextStyle(fontSize: 18))
          else
            ...completedRoutines.map(
                  (routine) {
                final String title = routine['title'];
                final int duration = routine['duration'] ?? 0;

                return ListTile(
                  leading: const Icon(
                    Icons.local_fire_department,
                    size: 35,
                    color: Colors.deepOrange,
                  ),
                  title: Text(title),
                  trailing: duration > 0
                      ? Text(
                    _formatDuration(duration),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }
}

