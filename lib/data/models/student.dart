import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 0)
class Student extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String roll;

  @HiveField(3)
  final int createdAtMs;

  @HiveField(4)
  final String groupId; // NEW

  Student({
    required this.id,
    required this.name,
    String? roll,
    required this.groupId, // NEW
    int? createdAtMs,
  })  : roll = (roll == null || roll.trim().isEmpty) ? id : roll.trim(),
        createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

  Student copyWith({
    String? name,
    String? roll,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      roll: roll ?? this.roll,
      groupId: groupId,
      createdAtMs: createdAtMs,
    );
  }
}
