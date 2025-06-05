import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kkubeo/tap_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSaving = false;

  Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('user_id');

    if (id != null) return id;

    if (kIsWeb) {
      id = const Uuid().v4().substring(0, 8);
    } else {
      final info = await DeviceInfoPlugin().androidInfo;
      id = info.id;
    }

    await prefs.setString('user_id', id);
    return id;
  }

  Future<void> _saveNickname() async {
    setState(() => _isSaving = true);

    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("닉네임을 입력해주세요")),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      final userId = await _getUserId();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nickname', nickname);

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'nickname': nickname,
      });

      // 성공 시 홈으로 이동
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TabScaffold(currentIndex: 1),
        ),
      );
    } catch (e, stackTrace) {
      print('Firestore 저장 오류: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("저장 중 문제가 발생했어요. 다시 시도해주세요.")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "닉네임 설정",
                  style: TextStyle(color: Colors.white, fontSize: 30),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "꾸버에서 사용할 닉네임 설정!",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.black,
                    hintText: '닉네임을 입력해주세요',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Colors.deepOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveNickname,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange, // 배경색
                      foregroundColor: Colors.white, // 글씨색
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("저장"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
