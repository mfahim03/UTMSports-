import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/auth_viewmodel.dart';
import 'manage_account.dart';
import 'manage_achievement.dart';
import 'view_feedback.dart';

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
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminPageContent();
}

//  STATE
class _AdminPageContent extends StatelessWidget {
  const _AdminPageContent();

  Route _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween(
            begin: const Offset(1.0, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );

  Future<void> _signOut(BuildContext context, AuthViewModel authVm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Are you sure you want to sign out of Admin Panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _T.maroon),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await authVm.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();
    final user   = context.watch<AuthViewModel>().currentUser;
    final mq     = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header 
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_T.maroonDark, _T.maroon],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                    20, mq.padding.top + 14, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.55),
                                width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFFAA3333),
                            child: Icon(Icons.person_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome back,',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white70,
                                      letterSpacing: 0.2)),
                              Text(
                                user?.name ?? 'Admin',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3),
                              ),
                            ],
                          ),
                        ),
                        _HeaderIconBtn(
                          icon: Icons.notifications_outlined,
                          badge: true,
                          onTap: () {},
                        ),
                        const SizedBox(width: 6),
                        _HeaderIconBtn(
                          icon: Icons.logout_rounded,
                          onTap: () => _signOut(context, authVm),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Stats row
                    Row(
                      children: [
                        _HeaderStat(
                            label: 'Role', value: 'Admin'),
                        const SizedBox(width: 12),
                        _HeaderStat(
                            label: 'Status', value: 'Active'),
                      ],
                    ),
                  ],
                ),
              ),

              // Section: Manage 
              _SectionTitle(label: 'Management'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.manage_accounts_rounded,
                        label: 'Manage\nAccounts',
                        subtitle: 'Users & roles',
                        accent: _T.maroon,
                        iconBg: _T.maroonFade,
                        onTap: () => Navigator.push(context,
                            _slide(const ManageAccountsPage())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.emoji_events_rounded,
                        label: 'Manage\nAchievements',
                        subtitle: 'Add / edit / remove',
                        accent: const Color(0xFF8B6914),
                        iconBg: const Color(0xFFFFF8EC),
                        onTap: () => Navigator.push(context,
                            _slide(const ManageAchievementsPage())),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _ActionCard(
                  icon: Icons.feedback_rounded,
                  label: 'View Student Feedback',
                  subtitle:
                      'Read feedback from students across Events, Facilities & App',
                  accent: const Color(0xFF0F5F8A),
                  iconBg: const Color(0xFFECF5FF),
                  onTap: () => Navigator.push(
                      context, _slide(const ViewFeedbackPage())),
                  wide: true,
                ),
              ),

              // Section: Quick links 
              _SectionTitle(label: 'Quick Links'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  children: [
                    _QuickLink(
                      icon: Icons.people_alt_outlined,
                      label: 'All Users',
                      onTap: () => Navigator.push(context,
                          _slide(const ManageAccountsPage())),
                    ),
                    _QuickLink(
                      icon: Icons.star_outline_rounded,
                      label: 'Organisers only',
                      onTap: () {
                        Navigator.push(
                          context,
                          _slide(const ManageAccountsPage()),
                        );
                        // ManageAccountsPage opens on tab 0;
                        // user can tap Organisers tab
                      },
                    ),
                    _QuickLink(
                      icon: Icons.school_outlined,
                      label: 'Students only',
                      onTap: () => Navigator.push(context,
                          _slide(const ManageAccountsPage())),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//  HEADER STAT CHIP
class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  letterSpacing: 0.3)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

//  HEADER ICON BUTTON
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

//  SECTION TITLE
class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _T.textHint,
              letterSpacing: 0.8)),
    );
  }
}

//  ACTION CARD  (press animation)
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accent;
  final Color iconBg;
  final VoidCallback onTap;
  final bool wide;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.iconBg,
    required this.onTap,
    this.wide = false,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _T.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _T.divider),
            boxShadow: _T.shadow,
          ),
          child: widget.wide
              ? Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon,
                          color: widget.accent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(widget.label,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _T.textPrimary)),
                          const SizedBox(height: 3),
                          Text(widget.subtitle,
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _T.textSecond)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: _T.textHint, size: 20),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon,
                          color: widget.accent, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.label,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _T.textPrimary,
                            height: 1.3)),
                    const SizedBox(height: 3),
                    Text(widget.subtitle,
                        style: const TextStyle(
                            fontSize: 11,
                            color: _T.textSecond)),
                  ],
                ),
        ),
      ),
    );
  }
}

//  QUICK LINK ROW
class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickLink(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.divider),
          boxShadow: _T.shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _T.maroonFade,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _T.maroon, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _T.textPrimary)),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: _T.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}