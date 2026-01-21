import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/local/hive_boxes.dart';
import '../../data/models/attendance.dart';
import '../../data/models/student.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 6));
  DateTime _to = DateTime.now();

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      _from = picked;
      if (_from.isAfter(_to)) _to = _from;
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;

    setState(() {
      _to = picked;
      if (_to.isBefore(_from)) _from = _to;
    });
  }

  bool _inRange(String dateKey) {
    final d = DateTime.tryParse(dateKey);
    if (d == null) return false;
    final start = DateTime(_from.year, _from.month, _from.day);
    final end = DateTime(_to.year, _to.month, _to.day, 23, 59, 59, 999);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = HiveBoxes.studentsBox();
    final attendanceBox = HiveBoxes.attendanceBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: _RangeChip(
                    label: 'From: ${_dateKey(_from)}',
                    icon: Icons.date_range,
                    onTap: _pickFrom,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RangeChip(
                    label: 'To: ${_dateKey(_to)}',
                    icon: Icons.event,
                    onTap: _pickTo,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                studentsBox.listenable(),
                attendanceBox.listenable(),
              ]),
              builder: (context, _) {
                final students = studentsBox.values.toList()
                  ..sort((a, b) => a.roll.compareTo(b.roll));

                if (students.isEmpty) {
                  return const Center(
                    child: Text('No students found. Import students first.'),
                  );
                }

                final records = attendanceBox.values
                    .where((r) => _inRange(r.dateKey))
                    .toList();

                final Map<String, _Summary> summary = {
                  for (final s in students) s.id: _Summary(),
                };

                final Map<String, Set<String>> daysMarkedByStudent = {
                  for (final s in students) s.id: <String>{},
                };

                for (final r in records) {
                  final sum = summary[r.studentId];
                  if (sum == null) continue;

                  daysMarkedByStudent[r.studentId]?.add(r.dateKey);

                  switch (r.status) {
                    case AttendanceStatus.present:
                      sum.present++;
                      break;
                    case AttendanceStatus.absent:
                      sum.absent++;
                      break;
                    case AttendanceStatus.late:
                      sum.late++;
                      break;
                  }
                }

                int totalP = 0, totalA = 0, totalL = 0;
                for (final s in students) {
                  final sum = summary[s.id]!;
                  totalP += sum.present;
                  totalA += sum.absent;
                  totalL += sum.late;
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _OverallCard(
                      from: _dateKey(_from),
                      to: _dateKey(_to),
                      totalPresent: totalP,
                      totalAbsent: totalA,
                      totalLate: totalL,
                      totalMarks: totalP + totalA + totalL,
                    ),
                    const SizedBox(height: 12),
                    ...students.map((s) {
                      final sum = summary[s.id]!;
                      final markedDays = daysMarkedByStudent[s.id]?.length ?? 0;
                      final totalMarks = sum.present + sum.absent + sum.late;

                      final percent = totalMarks == 0
                          ? 0.0
                          : (sum.present / totalMarks) * 100.0;

                      return Card(
                        child: ListTile(
                          title: Text(s.name),
                          subtitle: Text(
                            'ID: ${s.roll}\nMarked days: $markedDays | Total marks: $totalMarks',
                          ),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${percent.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('P:${sum.present} A:${sum.absent} L:${sum.late}'),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 18),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final String from;
  final String to;
  final int totalPresent;
  final int totalAbsent;
  final int totalLate;
  final int totalMarks;

  const _OverallCard({
    required this.from,
    required this.to,
    required this.totalPresent,
    required this.totalAbsent,
    required this.totalLate,
    required this.totalMarks,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary (Range)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('From $from  →  To $to'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniStat(label: 'Present', value: totalPresent),
                _MiniStat(label: 'Absent', value: totalAbsent),
                _MiniStat(label: 'Late', value: totalLate),
                _MiniStat(label: 'Total Marks', value: totalMarks),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primaryContainer,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Summary {
  int present = 0;
  int absent = 0;
  int late = 0;
}
