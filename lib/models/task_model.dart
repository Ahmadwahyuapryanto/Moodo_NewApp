import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime deadline;
  final String type;
  final bool isCompleted;
  final String leader;
  final List<String> members;
  final List<Map<String, dynamic>> comments;
  final List<Map<String, dynamic>> notes;
  final Map<String, String> memberStatus;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    required this.type,
    this.isCompleted = false,
    required this.leader,
    this.members = const [],
    this.comments = const [],
    this.notes = const [],
    this.memberStatus = const {},
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // --- FUNGSI PERBAIKAN UNTUK MENCEGAH TYPEERROR ---
    List<Map<String, dynamic>> parseList(dynamic listData) {
      if (listData == null || listData is! List) {
        return [];
      }
      List<Map<String, dynamic>> result = [];
      for (var item in listData) {
        // Jika item adalah String (format lama), ubah menjadi Map
        if (item is String) {
          result.add({'text': item, 'createdAt': Timestamp.now()});
        }
        // Jika sudah Map, langsung tambahkan
        else if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
      return result;
    }
    // ------------------------------------------------

    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      deadline: (data['deadline'] as Timestamp).toDate(),
      type: data['type'] ?? 'individual',
      isCompleted: data['isCompleted'] ?? false,
      leader: data['leader'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      // Gunakan fungsi perbaikan di sini
      comments: parseList(data['comments']),
      notes: parseList(data['notes']),
      memberStatus: Map<String, String>.from(data['memberStatus'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'deadline': Timestamp.fromDate(deadline),
      'type': type,
      'isCompleted': isCompleted,
      'leader': leader,
      'members': members,
      'comments': comments,
      'notes': notes,
      'memberStatus': memberStatus,
    };
  }
}