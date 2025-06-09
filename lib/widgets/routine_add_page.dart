import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoutineAddPage extends StatefulWidget {
  const RoutineAddPage({super.key});

  @override
  State<RoutineAddPage> createState() => _RoutineAddPageState();
}

class _RoutineAddPageState extends State<RoutineAddPage> {
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveRoutine() async {
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
          .add({
        'title': title,
        'createdAt': Timestamp.now(),
        'repeatDays': selectedDays,
      });

      if (!mounted) return;
      Navigator.pop(context,true);
    } catch (e) {
      print('❌ 루틴 저장 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('루틴 저장에 실패했어요. 다시 시도해주세요.')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("나만의 루틴 만들기")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "루틴 제목",
                border: OutlineInputBorder(),
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
                onPressed: _isSaving ? null : _saveRoutine,
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
