import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/user_model.dart';
import '../../viewmodel/admin_viewmodel.dart';

//  DESIGN TOKENS
class _T {
  static const maroon      = Color(0xFF800000);
  static const maroonDark  = Color(0xFF5C0000);
  static const maroonFade  = Color(0xFFF9F0F0);
  static const surface     = Color(0xFFFFFFFF);
  static const bg          = Color(0xFFF4EFEF);
  static const divider     = Color(0xFFEDE5E5);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecond  = Color(0xFF6B6B6B);
  static const textHint    = Color(0xFFAAAAAA);

  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x06000000), blurRadius: 4,  offset: Offset(0, 1)),
  ];
}

//  ROOT
class ManageAccountsPage extends StatelessWidget {
  const ManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminViewModel(),
      child: const _ManageAccountsContent(),
    );
  }
}

//  STATE
class _ManageAccountsContent extends StatefulWidget {
  const _ManageAccountsContent();

  @override
  State<_ManageAccountsContent> createState() =>
      _ManageAccountsContentState();
}

class _ManageAccountsContentState extends State<_ManageAccountsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<bool?> _confirm(String title, String body,
      {bool danger = false}) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      (danger ? Colors.red : _T.maroon).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  danger
                      ? Icons.delete_outline_rounded
                      : Icons.swap_horiz_rounded,
                  color: danger ? Colors.red : _T.maroon,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _T.textPrimary)),
              ),
            ],
          ),
          content: Text(body,
              style: const TextStyle(
                  fontSize: 13.5,
                  color: _T.textSecond,
                  height: 1.5)),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: _T.textSecond,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    danger ? Colors.red.shade600 : _T.maroon,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(danger ? 'Delete' : 'Confirm',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Accounts',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'All Users'),
              Tab(text: 'Students'),
              Tab(text: 'Organisers'),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar 
          Container(
            color: _T.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Focus(
              onFocusChange: (f) =>
                  setState(() => _searchFocused = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 46,
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _searchFocused
                        ? _T.maroon.withOpacity(0.45)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: _searchFocused ? _T.shadow : [],
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => vm.setSearch(v),
                  style: const TextStyle(
                      fontSize: 13.5, color: _T.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or matric…',
                    hintStyle: const TextStyle(
                        color: _T.textHint, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color:
                          _searchFocused ? _T.maroon : _T.textHint,
                      size: 20,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded,
                                size: 18, color: _T.textHint),
                            onPressed: () {
                              _searchCtrl.clear();
                              vm.setSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ),
          ),

          // User count summary 
          StreamBuilder<List<UserModel>>(
            stream: vm.usersStream,
            builder: (ctx, snap) {
              final all = snap.data ?? [];
              final students =
                  all.where((u) => u.role == 'student').length;
              final organisers =
                  all.where((u) => u.role == 'organiser').length;
              return Container(
                color: _T.surface,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  children: [
                    _StatPill(
                        label: 'Total',
                        count: all.length,
                        color: _T.maroon),
                    const SizedBox(width: 10),
                    _StatPill(
                        label: 'Students',
                        count: students,
                        color: const Color(0xFF0A7A5A)),
                    const SizedBox(width: 10),
                    _StatPill(
                        label: 'Organisers',
                        count: organisers,
                        color: const Color(0xFF8B6914)),
                  ],
                ),
              );
            },
          ),

          // Tab lists 
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: vm.usersStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: _T.maroon, strokeWidth: 2.5));
                }
                if (snap.hasError) {
                  return Center(
                      child: Text('Error: ${snap.error}',
                          style: const TextStyle(
                              color: _T.textSecond)));
                }

                final all = vm.filter(snap.data ?? []);
                final students = all
                    .where((u) => u.role == 'student')
                    .toList();
                final organisers = all
                    .where((u) => u.role == 'organiser')
                    .toList();

                return TabBarView(
                  controller: _tab,
                  children: [
                    _UserList(
                      users: all,
                      emptyMessage: 'No users found',
                      onToggle: (u) => _handleToggle(u, vm),
                      onDelete: (u) => _handleDelete(u, vm),
                    ),
                    _UserList(
                      users: students,
                      emptyMessage: 'No students found',
                      onToggle: (u) => _handleToggle(u, vm),
                      onDelete: (u) => _handleDelete(u, vm),
                    ),
                    _UserList(
                      users: organisers,
                      emptyMessage: 'No organisers yet',
                      onToggle: (u) => _handleToggle(u, vm),
                      onDelete: (u) => _handleDelete(u, vm),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleToggle(UserModel u, AdminViewModel vm) async {
    final isPromo = u.role == 'student';
    final ok = await _confirm(
      isPromo ? 'Make Organiser' : 'Revoke Organiser',
      isPromo
          ? 'Grant organiser privileges to ${u.name}?'
          : 'Remove organiser role from ${u.name}?',
    );
    if (ok == true) vm.toggleRole(u);
  }

  void _handleDelete(UserModel u, AdminViewModel vm) async {
    final ok = await _confirm(
      'Delete User',
      'Permanently remove ${u.name}? This cannot be undone.',
      danger: true,
    );
    if (ok == true) vm.deleteUser(u.uid);
  }
}

//  STAT PILL
class _StatPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatPill(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

//  USER LIST
class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final String emptyMessage;
  final ValueChanged<UserModel> onToggle;
  final ValueChanged<UserModel> onDelete;

  const _UserList({
    required this.users,
    required this.emptyMessage,
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _T.maroonFade,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.people_outline_rounded,
                  size: 36, color: _T.maroon),
            ),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _T.textSecond)),
            const SizedBox(height: 4),
            const Text('Try a different search term.',
                style: TextStyle(
                    fontSize: 12.5, color: _T.textHint)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: users.length,
      itemBuilder: (_, i) => _UserCard(
        user: users[i],
        onToggle: () => onToggle(users[i]),
        onDelete: () => onDelete(users[i]),
      ),
    );
  }
}

//  USER CARD
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOrganiser = user.role == 'organiser';
    final isAdmin     = user.role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOrganiser
              ? _T.maroon.withOpacity(0.3)
              : _T.divider,
          width: isOrganiser ? 1.5 : 1,
        ),
        boxShadow: _T.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isOrganiser
                          ? _T.maroon
                          : isAdmin
                              ? Colors.deepPurple
                              : const Color(0xFFE8E0E0),
                      child: Text(
                        user.name.isNotEmpty
                            ? user.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: (isOrganiser || isAdmin)
                              ? Colors.white
                              : _T.textSecond,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (isOrganiser)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: Color(0xFFFFD700),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.star_rounded,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
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
                            child: Text(user.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _T.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          _RoleBadge(role: user.role),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(user.email,
                          style: const TextStyle(
                              fontSize: 12, color: _T.textSecond),
                          overflow: TextOverflow.ellipsis),
                      if (user.matric != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 11, color: _T.textHint),
                            const SizedBox(width: 3),
                            Text(user.matric!,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _T.textHint)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isAdmin)
                      _RoleChip(
                        label:
                            isOrganiser ? 'Organiser' : 'Set Role',
                        icon: isOrganiser
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        active: isOrganiser,
                        onTap: onToggle,
                      ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 16,
                            color: Colors.red.shade400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//  ROLE CHIP
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _T.maroon : _T.maroonFade,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? _T.maroon : _T.maroon.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: active ? Colors.white : _T.maroon),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _T.maroon)),
          ],
        ),
      ),
    );
  }
}

//  ROLE BADGE
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (role) {
      'organiser' => (_T.maroon, 'Organiser'),
      'admin'     => (Colors.deepPurple, 'Admin'),
      _           => (const Color(0xFF0A7A5A), 'Student'),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.4)),
    );
  }
}