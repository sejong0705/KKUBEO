import 'package:flutter/material.dart';
import 'package:kkubeo/tap_scaffold.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nick_name.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 설정
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this, // 화면 리프레시와 애니메이션 타이밍 맞추기 위해 필요
    );

    _sizeAnimation = Tween<double>(begin: 60, end: 130).animate( //크기가 60에서 130 으로 변화
      CurvedAnimation(parent: _controller, curve: Curves.easeOut), // 속도를 부드럽게 해줌
    );

    _controller.forward(); // 애니메이션 바로 시작
    _checkNicknameAndNavigate(); // 닉네임 확인 후 화면 이동
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 기존 닉네임 체크는 그대로 유지
  Future<void> _checkNicknameAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2)); // 애니메이션과 맞춰서 2초 대기
    final prefs = await SharedPreferences.getInstance(); // 기기 로컬에 저장된 사용자 식별
    final nickname = prefs.getString('nickname');

    if (!mounted) return;

    if (nickname == null || nickname.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NicknameScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const TabScaffold(currentIndex: 1) // home_page.dart 이동
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Align(
        alignment: const Alignment(0, -0.3), // 중앙보다 위로 올림
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 고정된 공간 안에서 아이콘만 커지게
            SizedBox(
              height: 180, // 최종 크기에 맞춰 고정
              child: Center(
                child: AnimatedBuilder(
                  animation: _sizeAnimation,
                  builder: (context, child) {
                    return Text(
                      '🔥',
                      style: TextStyle(
                        fontSize: _sizeAnimation.value,
                        color: Colors.deepOrange,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'KKUBEO',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const Text(
              '당신의 하루, 꾸준히 버티기',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
