import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/user_model.dart';
import '../../viewmodel/admin_viewmodel.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'manage_achievement.dart';
import 'view_feedback.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
//  ROOT
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
//  STATE
// ─────────────────────────────────────────────────────────────────────────────
class _AdminPageContent extends StatefulWidget {
  const _AdminPageContent();

  @override
  State<_AdminPageContent> createState() => _AdminPageContentState();
}

class _AdminPageContentState extends State<_AdminPageContent>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final TabController _tab;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Confirm dialog ──────────────────────────────────────────────────────────
  Future<bool?> _confirm(
    String title,
    String body, {
    bool danger = false,
  }) =>
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
                  color: (danger ? Colors.red : _T.maroon).withOpacity(0.1),
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
                  fontSize: 13.5, color: _T.textSecond, height: 1.5)),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: _T.textSecond,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: danger ? Colors.red.shade600 : _T.maroon,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(danger ? 'Delete' : 'Confirm',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  // ── Sign-out ────────────────────────────────────────────────────────────────
  Future<void> _signOut(AuthViewModel authVm) async {
    final ok = await _confirm(
      'Sign Out',
      'Are you sure you want to sign out of Admin Panel?',
    );
    if (ok == true && mounted) {
      await authVm.signOut();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // ── Route helper ─────────────────────────────────────────────────────────────
  Route _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final adminVm = context.watch<AdminViewModel>();
    final authVm  = context.read<AuthViewModel>();
    final mq      = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Column(
          children: [
            _buildHeader(mq, authVm),
            _buildSearchBar(),
            _buildQuickActions(context),
            _buildTabHeader(),
            Expanded(child: _buildUserTabs(adminVm)),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader(MediaQueryData mq, AuthViewModel authVm) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.maroonDark, _T.maroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding:
          EdgeInsets.fromLTRB(20, mq.padding.top + 14, 20, 20),
      child: Row(
        children: [
          // Avatar with ring
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withOpacity(0.55), width: 2),
            ),
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFAA3333),
              child:
                  Icon(Icons.person_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          // Greeting
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        letterSpacing: 0.2)),
                Text('Admin',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3)),
              ],
            ),
          ),
          // Notification
          _HeaderIconBtn(
            icon: Icons.notifications_outlined,
            badge: true,
            onTap: () {},
          ),
          const SizedBox(width: 6),
          // Sign out
          _HeaderIconBtn(
            icon: Icons.logout_rounded,
            onTap: () => _signOut(authVm),
          ),
        ],
      ),
    );
  }

  // ── SEARCH BAR ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Focus(
        onFocusChange: (f) => setState(() => _searchFocused = f),
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
            onChanged: (v) =>
                context.read<AdminViewModel>().setSearch(v),
            style: const TextStyle(fontSize: 13.5, color: _T.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name, email or matric…',
              hintStyle: const TextStyle(color: _T.textHint, fontSize: 13),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: _searchFocused ? _T.maroon : _T.textHint,
                size: 20,
              ),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded,
                          size: 18, color: _T.textHint),
                      onPressed: () {
                        _searchCtrl.clear();
                        context.read<AdminViewModel>().setSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ),
    );
  }

  // ── QUICK ACTIONS ────────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      color: _T.surface,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.manage_accounts_rounded,
              label: 'Manage\nAccount',
              accent: _T.maroon,
              iconBg: _T.maroonFade,
              onTap: () {},
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.emoji_events_rounded,
              label: 'Manage\nAchievement',
              accent: const Color(0xFF8B6914),
              iconBg: const Color(0xFFFFF8EC),
              onTap: () => Navigator.push(
                  context, _slide(const ManageAchievementsPage())),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.feedback_rounded,
              label: 'View\nFeedback',
              accent: const Color(0xFF0F5F8A),
              iconBg: const Color(0xFFECF5FF),
              onTap: () => Navigator.push(
                  context, _slide(const ViewFeedbackPage())),
            ),
          ),
        ],
      ),
    );
  }

  // ── TAB HEADER ───────────────────────────────────────────────────────────────
  Widget _buildTabHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _T.surface,
        border: Border(bottom: BorderSide(color: _T.divider)),
      ),
      child: TabBar(
        controller: _tab,
        indicatorColor: _T.maroon,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: _T.maroon,
        unselectedLabelColor: _T.textSecond,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: const [
          Tab(text: 'All Users'),
          Tab(text: 'Organisers'),
        ],
      ),
    );
  }

  // ── USER TABS ────────────────────────────────────────────────────────────────
  Widget _buildUserTabs(AdminViewModel adminVm) {
    return StreamBuilder<List<UserModel>>(
      stream: adminVm.usersStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: _T.maroon, strokeWidth: 2.5));
        }
        if (snap.hasError) {
          return _ErrorState(message: '${snap.error}');
        }

        final all = adminVm.filter(snap.data ?? []);
        final organisers =
            all.where((u) => u.role == 'organiser').toList();

        return TabBarView(
          controller: _tab,
          children: [
            _UserList(
              users: all,
              scrollCtrl: _scrollCtrl,
              onToggle: (u) async {
                final isPromo = u.role == 'student';
                final ok = await _confirm(
                  isPromo ? 'Make Organiser' : 'Revoke Organiser',
                  isPromo
                      ? 'Grant organiser privileges to ${u.name}?'
                      : 'Remove organiser role from ${u.name}?',
                );
                if (ok == true) adminVm.toggleRole(u);
              },
              onDelete: (u) async {
                final ok = await _confirm(
                  'Delete User',
                  'Permanently remove ${u.name}? This cannot be undone.',
                  danger: true,
                );
                if (ok == true) adminVm.deleteUser(u.uid);
              },
            ),
            _UserList(
              users: organisers,
              scrollCtrl: ScrollController(),
              onToggle: (u) async {
                final ok = await _confirm(
                  'Revoke Organiser',
                  'Remove organiser role from ${u.name}?',
                );
                if (ok == true) adminVm.toggleRole(u);
              },
              onDelete: (u) async {
                final ok = await _confirm(
                  'Delete User',
                  'Permanently remove ${u.name}? This cannot be undone.',
                  danger: true,
                );
                if (ok == true) adminVm.deleteUser(u.uid);
              },
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER ICON BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (badge)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  QUICK ACTION CARD  (with press animation)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color iconBg;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.accent,
    required this.iconBg,
    required this.onTap,
  });

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.divider),
            boxShadow: _T.shadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  USER LIST
// ─────────────────────────────────────────────────────────────────────────────
class _UserList extends StatelessWidget {
  final List<UserModel> users;
  final ScrollController scrollCtrl;
  final ValueChanged<UserModel> onToggle;
  final ValueChanged<UserModel> onDelete;

  const _UserList({
    required this.users,
    required this.scrollCtrl,
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
            const Text('No users found',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _T.textSecond)),
            const SizedBox(height: 4),
            const Text('Try a different search term.',
                style: TextStyle(fontSize: 12.5, color: _T.textHint)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: users.length,
      itemBuilder: (ctx, i) => _UserCard(
        user: users[i],
        onToggle: () => onToggle(users[i]),
        onDelete: () => onDelete(users[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  USER CARD
// ─────────────────────────────────────────────────────────────────────────────
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
                // ── Avatar ────────────────────────────────────────
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
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // ── Info ──────────────────────────────────────────
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
                                fontSize: 14,
                                color: _T.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _RoleBadge(role: user.role),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        style: const TextStyle(
                            fontSize: 12, color: _T.textSecond),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.matric != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.badge_outlined,
                                size: 11, color: _T.textHint),
                            const SizedBox(width: 3),
                            Text(
                              user.matric!,
                              style: const TextStyle(
                                  fontSize: 11, color: _T.textHint),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Action buttons ────────────────────────────────
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isAdmin)
                      _RoleChip(
                        label: isOrganiser ? 'Organiser' : 'Set Role',
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
                            size: 16, color: Colors.red.shade400),
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

// ─────────────────────────────────────────────────────────────────────────────
//  ROLE CHIP  (toggle button inside card)
// ─────────────────────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _T.maroon : _T.maroonFade,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? _T.maroon
                : _T.maroon.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 12,
                color: active ? Colors.white : _T.maroon),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : _T.maroon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROLE BADGE
// ─────────────────────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ERROR STATE
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 40, color: _T.textHint),
          const SizedBox(height: 12),
          const Text('Something went wrong',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _T.textSecond)),
          const SizedBox(height: 4),
          Text(message,
              style: const TextStyle(
                  fontSize: 11.5, color: _T.textHint)),
        ],
      ),
    );
  }
}