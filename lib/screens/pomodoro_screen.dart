import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moodo_app/models/task_model.dart';

class PomodoroScreen extends StatefulWidget {
  final Task task;
  const PomodoroScreen({super.key, required this.task});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int _pomodoroDuration = 25 * 60; // 25 minutes
  Timer? _timer;
  int _remainingSeconds = _pomodoroDuration;
  bool _isTimerRunning = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          // TODO: Add logic for break time or finishing session
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _remainingSeconds = _pomodoroDuration;
    });
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Fokus'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Card(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formattedTime,
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Fokus pada: ${widget.task.title}',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetTimer,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.black),
                  child: const Text('Reset'),
                ),
                FloatingActionButton.large(
                  onPressed: _isTimerRunning ? _stopTimer : _startTimer,
                  child: Icon(_isTimerRunning ? Icons.pause : Icons.play_arrow),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Logic to mark as done
                  },
                  child: const Text('Selesai'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Catatan untuk tugas ini:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    // --- PERBAIKAN DI SINI ---
                    // Menggunakan widget.task.notes yang sudah diperbaiki
                    child: widget.task.notes.isEmpty
                        ? const Center(child: Text('Tidak ada catatan.'))
                        : ListView.builder(
                      itemCount: widget.task.notes.length,
                      itemBuilder: (context, index) {
                        final note = widget.task.notes[index];
                        return ListTile(
                          leading: const Icon(Icons.notes),
                          title: Text(note['text']),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}