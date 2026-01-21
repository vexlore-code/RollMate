import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/local/hive_boxes.dart';
import '../../data/models/attendance.dart';
import '../../data/models/student.dart';

class TakeAttendanceScreen extends StatefulWidget {
  const TakeAttendanceScreen({super.key});

  @override
  State<TakeAttendanceScreen> createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  late DateTime _selectedDate;
  final Map<String, AttendanceStatus> _statusByStudentId = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadExistingForDate();
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _statusByStudentId.clear();
    });

    await _loadExistingForDate();
  }

  Future<void> _loadExistingForDate() async {
    final attBox = HiveBoxes.attendanceBox();
    final dk = _dateKey(_selectedDate);

    // Load saved records for this date into local map
    for (final rec in attBox.values) {
      if (rec.dateKey == dk) {
        _statusByStudentId[rec.studentId] = rec.status;
      }
    }

    if (mounted) setState(() {});
  }

  void _setStatus(String studentId, AttendanceStatus status) {
    setState(() {
      _statusByStudentId[studentId] = status;
    });
  }

  Future<void> _saveAttendance(List<Student> students) async {
    final attBox = HiveBoxes.attendanceBox();
    final dk = _dateKey(_selectedDate);

    int saved = 0;

    for (final s in students) {
      final status = _statusByStudentId[s.id];
      if (status == null) continue; // not marked

      final id = AttendanceRecord.makeId(dateKey: dk, studentId: s.id);
      final record = AttendanceRecord(
        id: id,
        studentId: s.id,
        dateKey: dk,
        status: status,
      );

      await attBox.put(id, record);
      saved++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ✅ Marked: $saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = HiveBoxes.studentsBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Take Attendance'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pick date',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: studentsBox.listenable(),
        builder: (context, Box<Student> b, _) {
          final students = b.values.toList();
          students.sort((a, c) => a.roll.compareTo(c.roll));

          if (students.isEmpty) {
            return const Center(
              child: Text('No students found. Import students first.'),
            );
          }

          final dk = _dateKey(_selectedDate);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Date: $dk',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final s = students[index];
                    final status = _statusByStudentId[s.id];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  s.roll,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              children: [
                                _StatusChip(
                                  label: 'Present',
                                  selected: status == AttendanceStatus.present,
                                  onTap: () => _setStatus(
                                    s.id,
                                    AttendanceStatus.present,
                                  ),
                                ),
                                _StatusChip(
                                  label: 'Absent',
                                  selected: status == AttendanceStatus.absent,
                                  onTap: () => _setStatus(
                                    s.id,
                                    AttendanceStatus.absent,
                                  ),
                                ),
                                _StatusChip(
                                  label: 'Late',
                                  selected: status == AttendanceStatus.late,
                                  onTap: () => _setStatus(
                                    s.id,
                                    AttendanceStatus.late,
                                  ),
                                ),
                                if (status != null)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _statusByStudentId.remove(s.id);
                                      });
                                    },
                                    child: const Text('Clear'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _saveAttendance(students),
                      icon: const Icon(Icons.save),
                      label: const Text('Save Attendance'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
