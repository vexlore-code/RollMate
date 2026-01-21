import 'package:flutter/material.dart';

import '../../data/local/hive_boxes.dart';
import '../../data/models/class_group.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _deptCtrl = TextEditingController(text: 'CSE');
  final _batchCtrl = TextEditingController(text: '61');
  final _sectionCtrl = TextEditingController(text: 'C');

  @override
  void dispose() {
    _deptCtrl.dispose();
    _batchCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final dept = _deptCtrl.text.trim().isEmpty ? 'CSE' : _deptCtrl.text.trim();
    final batch = int.tryParse(_batchCtrl.text.trim()) ?? 61;
    final section = _sectionCtrl.text.trim().toUpperCase();
    if (section.isEmpty) return;

    final id = '${dept.toLowerCase()}_${batch}_${section.toLowerCase()}';

    final box = HiveBoxes.groupsBox();
    if (box.containsKey(id)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already exists')),
      );
      return;
    }

    final g = ClassGroup(
      id: id,
      department: dept,
      batch: batch,
      section: section,
    );

    await box.put(id, g);
    await HiveBoxes.setActiveGroupId(id);

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Created & selected: ${g.title} ✅')),
    );
  }

  Future<void> _select(String id) async {
    await HiveBoxes.setActiveGroupId(id);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _delete(String id) async {
    await HiveBoxes.groupsBox().delete(id);

    final active = HiveBoxes.getActiveGroupId();
    if (active == id) {
      await HiveBoxes.settingsBox().delete(HiveKeys.activeGroupId);
    }

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final box = HiveBoxes.groupsBox();
    final active = HiveBoxes.getActiveGroupId();

    final groups = box.values.toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a class',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _deptCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dept (e.g. CSE)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _batchCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Batch (e.g. 61)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _sectionCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Section (e.g. C)',
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
                      onPressed: _createGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('Create & Select'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your classes',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No classes yet. Create one above.')),
            )
          else
            ...groups.map((g) {
              final isActive = g.id == active;
              return Card(
                child: ListTile(
                  title: Text(g.title),
                  subtitle: Text('id: ${g.id}'),
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  onTap: () => _select(g.id),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(g.id),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
