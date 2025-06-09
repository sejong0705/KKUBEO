import 'package:flutter/material.dart';
import 'dart:async';

class TimerPage extends StatefulWidget {
  final String routineTitle;
  final Duration? initialDuration;

  const TimerPage({super.key, required this.routineTitle, this.initialDuration});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Stopwatch stopwatch = Stopwatch();
  Duration accumulated = Duration.zero;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    accumulated = widget.initialDuration ?? Duration.zero;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (stopwatch.isRunning) setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return [
      if (hours > 0) '${hours.toString().padLeft(2, '0')}',
      '${minutes.toString().padLeft(2, '0')}',
      '${seconds.toString().padLeft(2, '0')}'
    ].join(':');
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = accumulated + stopwatch.elapsed;

    return Scaffold(
      backgroundColor: stopwatch.isRunning ? Colors.indigo[900] : Colors
          .red[300],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // 상단 타이머 표시
              Center(
                child: Text(
                  formatDuration(elapsed),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // 가운데 재생/정지 버튼
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (stopwatch.isRunning) {
                      stopwatch.stop();
                    } else {
                      stopwatch.start();
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Icon(
                    stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // 저장 후 종료 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context, accumulated + stopwatch.elapsed);
                  },
                  icon: const Icon(Icons.download, size: 30,),
                  label: const Text('저장 후 종료'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}