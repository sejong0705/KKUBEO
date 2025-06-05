import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutineEditPage extends StatefulWidget {
  final String routineId;
  const RoutineEditPage({super.key, required this.routineId});

  @override
  State<RoutineEditPage> createState() => _RoutineEditPageState();
}

class _RoutineEditPageState extends State<RoutineEditPage> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, bool> repeatDays = {
    "월": false,
    "화": false,
    "수": false,
    "목": false,
    "금": false,
    "토": false,
    "일": false,
  };

  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutineData();
  }

  Future<void> _loadRoutineData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('routines')
        .doc(widget.routineId)
        .get();

    final data = doc.data();
    if (data == null) return;

    setState(() {
      _controller.text = data['title'] ?? '';
      final List<dynamic> selectedDays = data['repeatDays'] ?? [];
      for (final day in selectedDays) {
        if (repeatDays.containsKey(day)) {
          repeatDays[day] = true;
        }
      }
      _isLoading = false;
    });
  }

  Future<void> _updateRoutine() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception("user_id 없음");

      final selectedDays = repeatDays.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('routines')
          .doc(widget.routineId)
          .update({
        'title': title,
        'repeatDays': selectedDays,
      });

      if (!mounted) return;
      Navigator.pop(context, true); // 수정됨
    } catch (e) {
      print('❌ 루틴 업데이트 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴 수정에 실패했어요.')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("루틴 수정하기")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "루틴 제목 (수정 불가)",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "반복 요일 선택",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: repeatDays.keys.map((day) {
                final selected = repeatDays[day]!;
                return FilterChip(
                  label: Text(day),
                  selected: selected,
                  onSelected: (bool value) {
                    setState(() {
                      repeatDays[day] = value;
                    });
                  },
                  selectedColor: Colors.deepOrange,
                  checkmarkColor: Colors.white,
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("저장"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
