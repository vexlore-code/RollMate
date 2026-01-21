import 'package:hive/hive.dart';

part 'class_group.g.dart';

@HiveType(typeId: 3)
class ClassGroup extends HiveObject {
  @HiveField(0)
  final String id; // e.g. cse_61_c (or uuid)

  @HiveField(1)
  final String department; // CSE

  @HiveField(2)
  final int batch; // 61

  @HiveField(3)
  final String section; // C

  @HiveField(4)
  final int createdAtMs;

  ClassGroup({
    required this.id,
    required this.department,
    required this.batch,
    required this.section,
    int? createdAtMs,
  }) : createdAtMs = createdAtMs ?? DateTime.now().millisecondsSinceEpoch;

  String get title => '$department $batch - $section';
}
