import 'dart:async';

import 'package:flutter/material.dart';

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  int _seconds = 25 * 60;
  bool _isRunning = false;
  late Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        _resetTimer();
        return;
      }
      setState(() => _seconds--);
    });
    setState(() => _isRunning = true);
  }

  void _pauseTimer() {
    _timer.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer.cancel();
    setState(() {
      _seconds = 25 * 60;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');

    return AlertDialog(
      title: const Text('Pomodoro Timer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$minutes:$seconds',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!_isRunning)
                ElevatedButton(
                  onPressed: _startTimer,
                  child: const Text('Mulai'),
                )
              else
                ElevatedButton(
                  onPressed: _pauseTimer,
                  child: const Text('Jeda'),
                ),
              ElevatedButton(
                onPressed: _resetTimer,
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}