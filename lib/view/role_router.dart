import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'admin/admin_page.dart';
import 'organiser/organiser_dashboard.dart';
import 'student/student_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthViewModel>().currentUser;

    if (user == null) {
      // Safety net – should never happen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const SizedBox.shrink();
    }

    return switch (user.role) {
      'admin' => const AdminPage(),
      'organiser' => const OrganiserDashboard(),
      _ => const StudentDashboard(),
    };
  }
}