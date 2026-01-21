import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/student.dart';
import '../models/attendance.dart';
import '../models/class_group.dart';

class HiveBoxNames {
  static const String students = 'students_box';
  static const String attendance = 'attendance_box';
  static const String groups = 'groups_box';
  static const String settings = 'settings_box';
}

class HiveKeys {
  static const String activeGroupId = 'active_group_id';
}

class HiveBoxes {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(StudentAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(AttendanceRecordAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(AttendanceStatusAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(ClassGroupAdapter());

    await Hive.openBox<Student>(HiveBoxNames.students);
    await Hive.openBox<AttendanceRecord>(HiveBoxNames.attendance);
    await Hive.openBox<ClassGroup>(HiveBoxNames.groups);
    await Hive.openBox(HiveBoxNames.settings);

    _initialized = true;
  }

  static Box<Student> studentsBox() => Hive.box<Student>(HiveBoxNames.students);
  static Box<AttendanceRecord> attendanceBox() => Hive.box<AttendanceRecord>(HiveBoxNames.attendance);
  static Box<ClassGroup> groupsBox() => Hive.box<ClassGroup>(HiveBoxNames.groups);
  static Box settingsBox() => Hive.box(HiveBoxNames.settings);

  static String? getActiveGroupId() =>
      settingsBox().get(HiveKeys.activeGroupId) as String?;

  static Future<void> setActiveGroupId(String groupId) async {
    await settingsBox().put(HiveKeys.activeGroupId, groupId);
  }
}
