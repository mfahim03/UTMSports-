import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/event_viewmodel.dart';
import '../admin/view_feedback.dart';
import '../student/viewAchievement.dart';
import 'manage_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS  (matches admin_page.dart)
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
class OrganiserDashboard extends StatelessWidget {
  const OrganiserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventViewModel(),
      child: const _OrganiserDashboardContent(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _OrganiserDashboardContent extends StatelessWidget {
  const _OrganiserDashboardContent();

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

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: _T.maroon),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AuthViewModel>().signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final vm   = context.read<EventViewModel>();
    final uid  = FirebaseAuth.instance.currentUser?.uid ?? '';
    final mq   = MediaQuery.of(context);

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
              // ── Header ──────────────────────────────────────────────────
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
                        // Avatar ring
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.55),
                                width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFAA3333),
                            child: Text(
                              user?.name.isNotEmpty == true
                                  ? user!.name[0].toUpperCase()
                                  : 'O',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
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
                                user?.name ?? 'Organiser',
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
                          icon: Icons.logout_rounded,
                          onTap: () => _signOut(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats row — live event count
                    StreamBuilder(
                      stream: vm.organiserStream(uid),
                      builder: (ctx, snap) {
                        final count = snap.data?.length ?? 0;
                        return Row(
                          children: [
                            _HeaderStat(
                                label: 'Role',
                                value: 'Organiser'),
                            const SizedBox(width: 12),
                            _HeaderStat(
                                label: 'My Events',
                                value: '$count'),
                            const SizedBox(width: 12),
                            _HeaderStat(
                                label: 'System',
                                value: 'UTMSports+'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Section: Manage ────────────────────────────────────────
              const _SectionTitle(label: 'MANAGEMENT'),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ActionCard(
                  icon: Icons.event_rounded,
                  label: 'Manage Events',
                  subtitle: 'Create, edit & remove sports events',
                  accent: _T.maroon,
                  iconBg: _T.maroonFade,
                  onTap: () => Navigator.push(
                      context, _slide(const ManageEventsPage())),
                  wide: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ActionCard(
                  icon: Icons.feedback_rounded,
                  label: 'View Student Feedback',
                  subtitle:
                      'Read feedback from Events, Facilities & App',
                  accent: const Color(0xFF0F5F8A),
                  iconBg: const Color(0xFFECF5FF),
                  onTap: () => Navigator.push(
                      context, _slide(const ViewFeedbackPage())),
                  wide: true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _ActionCard(
                  icon: Icons.emoji_events_rounded,
                  label: 'View Achievements',
                  subtitle: 'Browse UTM athlete achievements',
                  accent: const Color(0xFF8B6914),
                  iconBg: const Color(0xFFFFF8EC),
                  onTap: () => Navigator.push(
                      context,
                      _slide(const ViewAchievementsPage())),
                  wide: true,
                ),
              ),

              // ── Section: My recent events preview ─────────────────────
              const _SectionTitle(label: 'MY RECENT EVENTS'),
              _RecentEvents(uid: uid, vm: vm, context: context,
                  onManage: () => Navigator.push(
                      context, _slide(const ManageEventsPage()))),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RECENT EVENTS PREVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _RecentEvents extends StatelessWidget {
  final String uid;
  final EventViewModel vm;
  final BuildContext context;
  final VoidCallback onManage;

  const _RecentEvents({
    required this.uid,
    required this.vm,
    required this.context,
    required this.onManage,
  });

  static const _categoryIcons = <String, IconData>{
    'Running':      Icons.directions_run,
    'Badminton':    Icons.sports_tennis,
    'Volleyball':   Icons.sports_volleyball,
    'Squash':       Icons.sports_handball,
    'Table Tennis': Icons.sports_tennis,
    'Other':        Icons.emoji_events,
  };

  @override
  Widget build(BuildContext ctx) {
    return StreamBuilder(
      stream: vm.organiserStream(uid),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(
                    color: _T.maroon, strokeWidth: 2)),
          );
        }

        final events = (snap.data ?? []).take(3).toList();

        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: _T.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _T.divider),
                boxShadow: _T.shadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _T.maroonFade,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.event_outlined,
                        color: _T.maroon, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text('No events yet',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _T.textSecond)),
                  const SizedBox(height: 4),
                  const Text('Tap Manage Events to create one',
                      style: TextStyle(
                          fontSize: 12, color: _T.textHint)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: onManage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _T.maroon,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Create Event',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            ...events.map((e) {
              final icon =
                  _categoryIcons[e.category] ?? Icons.emoji_events;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _T.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _T.divider),
                    boxShadow: _T.shadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _T.maroonFade,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(icon, color: _T.maroon, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(e.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: _T.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(
                              '${e.date}  ·  ${e.location}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: _T.textSecond),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                _Pill(
                                    label: e.category,
                                    color: _T.maroon),
                                const SizedBox(width: 6),
                                _Pill(
                                    label: e.spots,
                                    color: const Color(0xFF0A7A5A)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if ((snap.data ?? []).length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: GestureDetector(
                  onTap: onManage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _T.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _T.divider),
                    ),
                    child: const Text('See all events →',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _T.maroon)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _HeaderIconBtn(
      {required this.icon, required this.onTap, this.badge = false});

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
                        shape: BoxShape.circle)),
              ),
          ],
        ),
      ),
    );
  }
}

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
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    Icon(widget.icon, color: widget.accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
              const Icon(Icons.chevron_right_rounded,
                  color: _T.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}