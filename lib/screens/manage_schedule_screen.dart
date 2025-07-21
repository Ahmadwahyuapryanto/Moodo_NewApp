import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moodo_app/models/schedule_model.dart';

class ManageScheduleScreen extends StatefulWidget {
  const ManageScheduleScreen({super.key});

  @override
  State<ManageScheduleScreen> createState() => _ManageScheduleScreenState();
}

class _ManageScheduleScreenState extends State<ManageScheduleScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Fungsi untuk menampilkan dialog tambah/edit jadwal
  void _showScheduleDialog({Schedule? schedule}) {
    final _formKey = GlobalKey<FormState>();
    final _subjectController =
    TextEditingController(text: schedule?.subjectName);
    String _selectedDay = schedule?.day ?? 'Senin';
    TimeOfDay _startTime = schedule?.startTime ?? TimeOfDay.now();
    TimeOfDay _endTime = schedule?.endTime ??
        TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(schedule == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _subjectController,
                        decoration:
                        const InputDecoration(labelText: 'Nama Mata Pelajaran'),
                        validator: (value) =>
                        value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedDay,
                        decoration: const InputDecoration(labelText: 'Hari'),
                        items: [
                          'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
                        ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (value) =>
                            setDialogState(() => _selectedDay = value!),
                      ),
                      ListTile(
                        title: const Text('Waktu Mulai'),
                        subtitle: Text(_startTime.format(context)),
                        onTap: () async {
                          final time = await showTimePicker(
                              context: context, initialTime: _startTime);
                          if (time != null) {
                            setDialogState(() => _startTime = time);
                          }
                        },
                      ),
                      ListTile(
                        title: const Text('Waktu Selesai'),
                        subtitle: Text(_endTime.format(context)),
                        onTap: () async {
                          final time = await showTimePicker(
                              context: context, initialTime: _endTime);
                          if (time != null) {
                            setDialogState(() => _endTime = time);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final newSchedule = Schedule(
                        id: schedule?.id ?? '', // ID akan dibuat oleh Firestore
                        subjectName: _subjectController.text,
                        day: _selectedDay,
                        startTime: _startTime,
                        endTime: _endTime,
                        userId: currentUser!.uid,
                      );
                      if (schedule == null) {
                        FirebaseFirestore.instance
                            .collection('schedules')
                            .add(newSchedule.toFirestore());
                      } else {
                        FirebaseFirestore.instance
                            .collection('schedules')
                            .doc(schedule.id)
                            .update(newSchedule.toFirestore());
                      }
                      Navigator.pop(context);
                    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Jadwal Pelajaran'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('schedules')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final schedules = snapshot.data!.docs
              .map((doc) => Schedule.fromFirestore(doc))
              .toList();

          // Kelompokkan berdasarkan hari
          Map<String, List<Schedule>> groupedSchedules = {};
          for (var s in schedules) {
            (groupedSchedules[s.day] ??= []).add(s);
          }
          final sortedDays = groupedSchedules.keys.toList()..sort((a,b) {
            const dayOrder = {'Senin':1, 'Selasa':2, 'Rabu':3, 'Kamis':4, 'Jumat':5, 'Sabtu':6, 'Minggu':7};
            return dayOrder[a]!.compareTo(dayOrder[b]!);
          });


          return ListView(
            children: sortedDays.map((day) {
              final daySchedules = groupedSchedules[day]!;
              return ExpansionTile(
                title: Text(day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                initiallyExpanded: true,
                children: daySchedules.map((schedule) {
                  return ListTile(
                    title: Text(schedule.subjectName),
                    subtitle: Text(
                        '${schedule.startTime.format(context)} - ${schedule.endTime.format(context)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showScheduleDialog(schedule: schedule),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                          onPressed: () => FirebaseFirestore.instance
                              .collection('schedules')
                              .doc(schedule.id)
                              .delete(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showScheduleDialog,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Jadwal Pelajaran',
      ),
    );
  }
}