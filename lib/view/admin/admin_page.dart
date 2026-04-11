import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/user_model.dart';
import '../../viewmodel/admin_viewmodel.dart';
import '../../viewmodel/auth_viewmodel.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminViewModel(),
      child: const _AdminPageContent(),
    );
  }
}

class _AdminPageContent extends StatefulWidget {
  const _AdminPageContent();

  @override
  State<_AdminPageContent> createState() => _AdminPageContentState();
}

class _AdminPageContentState extends State<_AdminPageContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();

  static const _maroon = Color(0xFF800000);
  static const _darkMaroon = Color(0xFF3D0000);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      context.read<AdminViewModel>().setSearch(_searchCtrl.text);
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Confirm dialog ──────────────────────────────────────────────────────
  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child:
                    Text(title, style: const TextStyle(color: _maroon))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final adminVm = context.watch<AdminViewModel>();
    final authVm = context.read<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F0),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Admin Panel',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text('UTMSports+',
                style: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.7))),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await authVm.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or matric…',
                    hintStyle:
                        TextStyle(color: Colors.white.withOpacity(0.55)),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white70, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white70, size: 18),
                            onPressed: () => _searchCtrl.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.15),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tab,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'All Users'),
                  Tab(text: 'Organisers'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: adminVm.usersStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _maroon));
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }

          final all = adminVm.filter(snap.data ?? []);
          final organisers =
              all.where((u) => u.role == 'organiser').toList();

          return TabBarView(
            controller: _tab,
            children: [
              _UserList(
                users: all,
                adminVm: adminVm,
                onToggle: (u) async {
                  final isPromotion = u.role == 'student';
                  final ok = await _confirm(
                    isPromotion ? 'Make Organiser' : 'Revoke Organiser',
                    isPromotion
                        ? '${u.name} will be assigned as an Organiser.'
                        : 'Remove Organiser role from ${u.name}?',
                  );
                  if (ok == true) adminVm.toggleRole(u);
                },
                onDelete: (u) async {
                  final ok = await _confirm('Delete User',
                      'Permanently remove ${u.name} from the system?');
                  if (ok == true) adminVm.deleteUser(u.uid);
                },
              ),
              _UserList(
                users: organisers,
                adminVm: adminVm,
                onToggle: (u) async {
                  final ok = await _confirm('Revoke Organiser',
                      'Remove Organiser role from ${u.name}?');
                  if (ok == true) adminVm.toggleRole(u);
                },
                onDelete: (u) async {
                  final ok = await _confirm('Delete User',
                      'Permanently remove ${u.name} from the system?');
                  if (ok == true) adminVm.deleteUser(u.uid);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── User list ──────────────────────────────────────────────────────────────

class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final AdminViewModel adminVm;
  final ValueChanged<UserModel> onToggle;
  final ValueChanged<UserModel> onDelete;

  const _UserList({
    required this.users,
    required this.adminVm,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No users found',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: users.length,
      itemBuilder: (ctx, i) => _UserCard(
        user: users[i],
        onToggle: () => onToggle(users[i]),
        onDelete: () => onDelete(users[i]),
      ),
    );
  }
}

// ── Individual user card ───────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onToggle,
    required this.onDelete,
  });

  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    final isOrganiser = user.role == 'organiser';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOrganiser
            ? Border.all(color: _maroon.withOpacity(0.35), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isOrganiser ? _maroon : Colors.grey.shade200,
              child: Text(
                user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: isOrganiser ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleBadge(role: user.role),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.email,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.matric != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.matric!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle organiser button
                Tooltip(
                  message: isOrganiser
                      ? 'Revoke Organiser'
                      : 'Make Organiser',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: isOrganiser
                          ? _maroon
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOrganiser
                            ? _maroon
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: InkWell(
                      onTap: onToggle,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isOrganiser
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: isOrganiser
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOrganiser ? 'Organiser' : 'Set Role',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isOrganiser
                                    ? Colors.white
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Delete button
                Tooltip(
                  message: 'Delete user',
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.red.shade400),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role badge ─────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (role) {
      'organiser' => (const Color(0xFF800000), 'Organiser'),
      'admin' => (Colors.deepPurple, 'Admin'),
      _ => (Colors.teal, 'Student'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3),
      ),
    );
  }
}