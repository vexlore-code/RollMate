import 'package:flutter/material.dart';

import 'data/local/hive_boxes.dart';
import 'features/students/students_screen.dart';
import 'features/attendance/take_attendance_screen.dart';
import 'features/reports/reports_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveBoxes.init();
  runApp(const RollMateApp());
}

class RollMateApp extends StatelessWidget {
  const RollMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RollMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _go(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RollMate'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HomeButton(
              title: 'Students',
              icon: Icons.people,
              onTap: () => _go(context, StudentsScreen()),
            ),
            const SizedBox(height: 12),
            _HomeButton(
              title: 'Take Attendance',
              icon: Icons.check_circle,
              onTap: () => _go(context, TakeAttendanceScreen()),
            ),
            const SizedBox(height: 12),
            _HomeButton(
              title: 'Reports',
              icon: Icons.bar_chart,
              onTap: () => _go(context, ReportsScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(icon, size: 28),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
