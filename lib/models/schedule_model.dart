import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String subjectName;
  final String day; // Senin, Selasa, dst.
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String userId;

  Schedule({
    required this.id,
    required this.subjectName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.userId,
  });

  // Konversi dari Firestore ke objek Schedule
  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      subjectName: data['subjectName'] ?? '',
      day: data['day'] ?? '',
      // Konversi string 'HH:mm' dari Firestore ke TimeOfDay
      startTime: TimeOfDay(
        hour: int.parse(data['startTime'].split(':')[0]),
        minute: int.parse(data['startTime'].split(':')[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(data['endTime'].split(':')[0]),
        minute: int.parse(data['endTime'].split(':')[1]),
      ),
      userId: data['userId'] ?? '',
    );
  }

  // Konversi dari objek Schedule ke Map untuk disimpan di Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'subjectName': subjectName,
      'day': day,
      // Simpan sebagai string 'HH:mm' agar mudah di-query
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'userId': userId,
    };
  }
}