// MOODO_App-main/lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:moodo_app/models/schedule_model.dart';
import 'package:moodo_app/models/task_model.dart';
import 'package:moodo_app/screens/manage_schedule_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:holiday_id/holiday_id.dart';

// --- Model dan Enum Anda (Tidak Diubah) ---
class CalendarEvent {
  final String title;
  final DateTime time;
  final EventType type;

  CalendarEvent({required this.title, required this.time, required this.type});
}

enum EventType { task, schedule, holiday, activity }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  Map<DateTime, List<CalendarEvent>> _allEvents = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _fetchAllEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  // =========================================================
  // =========> PERBAIKAN ERROR DIMULAI DI FUNGSI INI <=========
  // =========================================================
  void _showAddActivityDialog() {
    final _activityController = TextEditingController();
    TimeOfDay? _selectedTime = TimeOfDay.now(); // Tetap diinisialisasi di sini

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Kegiatan Baru'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tanggal: ${DateFormat('d MMMM yyyy').format(_selectedDay!)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _activityController,
                    decoration: const InputDecoration(labelText: 'Nama Kegiatan'),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Waktu Kegiatan'),
                    // --- INI BAGIAN YANG DIPERBAIKI ---
                    // Memberikan teks default jika _selectedTime null untuk menghindari error
                    subtitle: Text(_selectedTime?.format(context) ?? 'Ketuk untuk memilih waktu'),
                    // ------------------------------------
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime ?? TimeOfDay.now(),
                      );
                      // Hanya update jika pengguna tidak menekan tombol batal (cancel)
                      if (time != null) {
                        setDialogState(() {
                          _selectedTime = time;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Pastikan _selectedTime tidak null sebelum menyimpan
                    if (_activityController.text.isEmpty || _selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama kegiatan dan waktu tidak boleh kosong!')),
                      );
                      return;
                    }
                    _saveActivity(
                      _activityController.text,
                      _selectedTime!,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // =========================================================
  // ==========> PERBAIKAN ERROR SELESAI <===========
  // =========================================================


  // Fungsi lain tidak diubah, hanya memastikan kelengkapan kode
  Future<void> _saveActivity(String title, TimeOfDay time) async {
    if (currentUser == null || _selectedDay == null) return;
    final activityDateTime = DateTime(_selectedDay!.year, _selectedDay!.month,
        _selectedDay!.day, time.hour, time.minute);
    await FirebaseFirestore.instance.collection('tasks').add({
      'title': title, 'description': 'Kegiatan pribadi',
      'deadline': Timestamp.fromDate(activityDateTime), 'type': 'activity',
      'isCompleted': false, 'leader': currentUser!.uid,
      'members': [currentUser!.uid], 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _fetchAllEvents() {
    if (currentUser == null) return;
    FirebaseFirestore.instance.collection('tasks').where('members', arrayContains: currentUser!.uid)
        .snapshots().listen((_) => _updateEvents());
    FirebaseFirestore.instance.collection('schedules').where('userId', isEqualTo: currentUser!.uid)
        .snapshots().listen((_) => _updateEvents());
    _updateEvents();
  }

  Future<void> _updateEvents() async {
    if (currentUser == null) return;
    final taskSnapshot = await FirebaseFirestore.instance.collection('tasks')
        .where('members', arrayContains: currentUser!.uid).get();
    final scheduleSnapshot = await FirebaseFirestore.instance.collection('schedules')
        .where('userId', isEqualTo: currentUser!.uid).get();
    Map<DateTime, List<CalendarEvent>> events = {};
    final holidays = HolidayId().getHolidays(filterYear: DateTime.now().year);
    for (var holiday in holidays) {
      if (holiday.date != null) {
        final holidayDate = DateTime.utc(holiday.date!.year, holiday.date!.month, holiday.date!.day);
        (events[holidayDate] ??= []).add(
            CalendarEvent(title: holiday.name, time: holidayDate, type: EventType.holiday));
      }
    }
    for (var doc in taskSnapshot.docs) {
      final task = Task.fromFirestore(doc);
      final deadlineDate = DateTime.utc(task.deadline.year, task.deadline.month, task.deadline.day);
      final eventType = task.type == 'activity' ? EventType.activity : EventType.task;
      (events[deadlineDate] ??= []).add(CalendarEvent(title: task.title, time: task.deadline, type: eventType));
    }
    final schedules = scheduleSnapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();
    final now = DateTime.now();
    for (int i = 0; i < 60; i++) {
      final day = now.add(Duration(days: i));
      final dayOfWeek = DateFormat('EEEE', 'id_ID').format(day);
      for (var schedule in schedules) {
        if (schedule.day == dayOfWeek) {
          final scheduleDate = DateTime.utc(day.year, day.month, day.day);
          final scheduleTime = DateTime(day.year, day.month, day.day, schedule.startTime.hour, schedule.startTime.minute);
          (events[scheduleDate] ??= []).add(
              CalendarEvent(title: schedule.subjectName, time: scheduleTime, type: EventType.schedule));
        }
      }
    }
    events.forEach((day, eventList) {
      eventList.sort((a, b) => a.time.compareTo(b.time));
    });
    if (mounted) {
      setState(() {
        _allEvents = events;
      });
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dateOnly = DateTime.utc(day.year, day.month, day.day);
    return _allEvents[dateOnly] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  Widget? _holidayBuilder(BuildContext context, DateTime day, DateTime focusedDay) {
    final events = _getEventsForDay(day);
    bool isHoliday = events.any((event) => event.type == EventType.holiday);
    if (isHoliday) {
      return Center(
        child: Text(
          '${day.day}',
          style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            onPressed: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (context) => const ManageScheduleScreen()),
              );
            },
            tooltip: 'Kelola Jadwal Pelajaran',
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            locale: 'id_ID',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              defaultBuilder: _holidayBuilder,
              todayBuilder: (context, day, focusedDay) {
                final holidayWidget = _holidayBuilder(context, day, focusedDay);
                if (holidayWidget != null) {
                  return Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text('${day.day}',
                          style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87,),
              weekendTextStyle: TextStyle(color: Theme.of(context).colorScheme.error.withOpacity(0.8)),
              outsideTextStyle: TextStyle(color: Colors.grey.shade500),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Divider(height: 8.0),
          Expanded(
            child: ValueListenableBuilder<List<CalendarEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada jadwal atau tugas pada hari ini.'),
                  );
                }
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    IconData icon; Color color; String subtitle = '';
                    switch (event.type) {
                      case EventType.task: icon = Icons.task_alt; color = Colors.blue; subtitle = 'Tugas'; break;
                      case EventType.schedule: icon = Icons.schedule; color = Colors.green; subtitle = 'Pelajaran'; break;
                      case EventType.holiday: icon = Icons.celebration; color = Colors.red; subtitle = 'Hari Libur Nasional'; break;
                      case EventType.activity: icon = Icons.local_activity; color = Colors.orange; subtitle = 'Kegiatan'; break;
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0,),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: color.withOpacity(0.7), width: 1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: ListTile(
                          leading: Icon(icon, color: color),
                          title: Text(event.title),
                          subtitle: Text(subtitle),
                          trailing: event.type != EventType.holiday ? Text(DateFormat('HH:mm').format(event.time)) : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddActivityDialog,
        tooltip: 'Tambah Kegiatan',
        child: const Icon(Icons.add),
      ),
    );
  }
}