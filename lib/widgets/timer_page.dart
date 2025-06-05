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
      appBar: AppBar(title: Text('${widget.routineTitle} 타이머')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatDuration(elapsed),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      stopwatch.start();
                    });
                  },
                  child: const Text('시작'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      stopwatch.stop();
                    });
                  },
                  child: const Text('정지'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, accumulated + stopwatch.elapsed);
                  },
                  child: const Text('저장 후 종료'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}