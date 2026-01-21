import 'package:hive/hive.dart';

part 'attendance.g.dart';

/// Attendance status:
/// present = 0, absent = 1, late = 2
@HiveType(typeId: 2)
enum AttendanceStatus {
  @HiveField(0)
  present,

  @HiveField(1)
  absent,

  @HiveField(2)
  late,
}

@HiveType(typeId: 1)
class AttendanceRecord extends HiveObject {
  /// Primary key-like id (we will store as: yyyy-mm-dd__studentId)
  @HiveField(0)
  final String id;

  /// Student id (uuid/string)
  @HiveField(1)
  final String studentId;

  /// Date key: yyyy-mm-dd (keep it simple for filtering)
  @HiveField(2)
  final String dateKey;

  @HiveField(3)
  AttendanceStatus status;

  /// Saved timestamp (optional but useful)
  @HiveField(4)
  final int createdAtMs;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.dateKey,
    required this.status,
    int? createdAtMs,
  }) : createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

  /// Helper for building a consistent unique id
  static String makeId({required String dateKey, required String studentId}) {
    return '${dateKey}__${studentId}';
  }
}
