import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/local/hive_boxes.dart';
import '../../data/models/class_group.dart';
import '../../data/models/student.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  static const List<String> _departments = [
    'CSE', 'EEE', 'BBA', 'CE', 'ME', 'IPE', 'TE', 'ARCH'
  ];

  static const List<String> _sections = ['A', 'B', 'C', 'D', 'E', 'F'];

  late String _dept;
  late int _batch;
  late String _section;

  String? _activeGroupId;

  @override
  void initState() {
    super.initState();
    _dept = 'CSE';
    _batch = 61;
    _section = 'C';
    _activeGroupId = HiveBoxes.getActiveGroupId();
  }

  List<int> get _batchList => List<int>.generate(16, (i) => 55 + i); // 55..70

  String _makeGroupId(String dept, int batch, String section) {
    return '${dept.toLowerCase()}_${batch}_${section.toLowerCase()}';
  }

  Future<void> _selectGroup() async {
    final gid = _makeGroupId(_dept, _batch, _section);

    final gBox = HiveBoxes.groupsBox();
    if (!gBox.containsKey(gid)) {
      await gBox.put(
        gid,
        ClassGroup(
          id: gid,
          department: _dept,
          batch: _batch,
          section: _section,
        ),
      );
    }

    await HiveBoxes.setActiveGroupId(gid);

    setState(() {
      _activeGroupId = gid;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: ${_dept} $_batch - $_section ✅')),
    );
  }

  Future<void> _pasteImport() async {
    final gid = _activeGroupId;
    if (gid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select Dept/Batch/Section first')),
      );
      return;
    }

    final controller = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste Students (ID + Name)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                'Example (your ID):\n242-115-126\tMd. Jubayer Hasan Munna',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText:
                  'Paste each student in a new line, for example:\n'
                      '242-115-126\tYour Name\n'
                      '242-115-154\tAnother Name\n\n'
                      'Tip: You can directly copy and paste data from Excel or a CSV file.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.upload),
                      label: const Text('Import'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    final raw = controller.text;
    final lines = raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    int added = 0;
    int skipped = 0;
    int bad = 0;

    final sBox = HiveBoxes.studentsBox();

    for (final line in lines) {
      String? sid;
      String? name;

      // TAB split
      if (line.contains('\t')) {
        final parts = line
            .split('\t')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          sid = parts.first;
          name = parts.sublist(1).join(' ');
        }
      }

      // COMMA split
      if ((sid == null || name == null) && line.contains(',')) {
        final parts = line
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          sid = parts.first;
          name = parts.sublist(1).join(' ');
        }
      }

      // MULTI-SPACE split
      if (sid == null || name == null) {
        final parts = line
            .split(RegExp(r'\s{2,}'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (parts.length >= 2) {
          sid = parts.first;
          name = parts.sublist(1).join(' ');
        }
      }

      if (sid == null || name == null || sid.isEmpty || name.isEmpty) {
        bad++;
        continue;
      }

      final key = '${gid}__${sid}';
      if (sBox.containsKey(key)) {
        skipped++;
        continue;
      }

      final student = Student(
        id: sid,
        name: name,
        roll: sid,
        groupId: gid,
      );

      await sBox.put(key, student);
      added++;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Import ✅ Added:$added Skipped:$skipped Bad:$bad')),
    );

    setState(() {});
  }

  Future<void> _deleteStudent(String key) async {
    await HiveBoxes.studentsBox().delete(key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sBox = HiveBoxes.studentsBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          TextButton.icon(
            onPressed: _pasteImport,
            icon: const Icon(Icons.paste),
            label: const Text('Paste Import'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Class',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _dept,
                            items: _departments
                                .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text(d),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => _dept = v ?? 'CSE'),
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _batch,
                            items: _batchList
                                .map((b) => DropdownMenuItem(
                              value: b,
                              child: Text(b.toString()),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => _batch = v ?? 61),
                            decoration: const InputDecoration(
                              labelText: 'Batch',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _section,
                            items: _sections
                                .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s),
                            ))
                                .toList(),
                            onChanged: (v) => setState(() => _section = v ?? 'C'),
                            decoration: const InputDecoration(
                              labelText: 'Section',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _selectGroup,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Select'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _activeGroupId == null
                          ? 'Active: (none)'
                          : 'Active groupId: $_activeGroupId',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: sBox.listenable(),
              builder: (context, Box<Student> b, _) {
                final gid = _activeGroupId;
                if (gid == null) {
                  return const Center(
                    child: Text('Select Dept/Batch/Section to load students.'),
                  );
                }

                final entries = b.toMap().entries.where((e) {
                  final key = e.key.toString();
                  return key.startsWith('${gid}__');
                }).toList();

                entries.sort((a, c) => a.value.roll.compareTo(c.value.roll));

                if (entries.isEmpty) {
                  return const Center(
                    child: Text('No students yet. Use Paste Import.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final key = entries[i].key.toString();
                    final s = entries[i].value;

                    return Card(
                      child: ListTile(
                        title: Text(s.name),
                        subtitle: Text('ID: ${s.roll}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteStudent(key),
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
    );
  }
}
