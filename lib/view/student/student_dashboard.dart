import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/auth_viewmodel.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF800000),
        foregroundColor: Colors.white,
        title: const Text('UTMSports+',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AuthViewModel>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer,
                size: 72, color: Color(0xFF800000)),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.name ?? 'Student'}!',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Student Dashboard',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}