import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kkubeo/splash_screen.dart';
import 'package:kkubeo/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  String? userId = prefs.getString('user_id');

  bool isDark = true; // 기본값

  if (userId != null) {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      isDark = snapshot.data()?['isDarkMode'] ?? true;
      await prefs.setBool('isDarkMode', isDark); // 로컬에도 동기화
      print('Firestore에서 불러온 테마 상태: $isDark');
    } catch (e) {
      print('Firestore에서 테마 상태 불러오기 실패: $e');
    }
  } else {
    isDark = prefs.getBool('isDarkMode') ?? true;
    print('SharedPreferences에서 불러온 테마 상태: $isDark');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider.init(isDark),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '꾸버티기',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepOrange,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,
      ),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(), // 또는 바로 HomePage()
    );
  }
}
