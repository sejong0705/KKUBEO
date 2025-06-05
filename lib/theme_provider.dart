import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  // main()에서 직접 isDark 값을 넘겨줌
  ThemeProvider.init(bool isDark)
      : _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

  // 현재 테마 상태
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    await Future.delayed(Duration(milliseconds: 300));

    // Firebase Firestore에도 저장
    try {
      final userId = prefs.getString('user_id');
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update(
            {
              'isDarkMode': isDark,
            });
        print('Firestore에 테마 상태 저장 완료');
      }
    } catch (e) {
      print('Firestore 테마 저장 실패: $e');
    }
  }
}
