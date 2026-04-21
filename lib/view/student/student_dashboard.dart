import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/event_model.dart';
import '../../model/booking_model.dart';
import '../../model/achievement_model.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/booking_viewmodel.dart';
import '../../viewmodel/achievement_viewmodel.dart';
import '../../viewmodel/event_viewmodel.dart';
import 'editProfile.dart';
import 'viewEvent.dart';
import 'bookCourt.dart';
import 'viewBooking.dart';
import 'viewAchievement.dart';
import 'submitFeedback.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentTab = 0;
  int _navIndex   = 0;

  // Design tokens (matches admin/organiser) 
  static const _maroon     = Color(0xFF800000);
  static const _maroonDark = Color(0xFF5C0000);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        ChangeNotifierProvider(create: (_) => AchievementViewModel()),
        ChangeNotifierProvider(create: (_) => EventViewModel()),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          body: Builder(builder: (ctx) {
            return IndexedStack(
              index: _navIndex,
              children: [
                _buildHome(ctx, user),
                const ViewEventsPage(embedded: true),
                const BookFacilityPage(embedded: true),
                const ViewBookingPage(embedded: true),
                const SubmitFeedbackPage(embedded: true),
              ],
            );
          }),
          bottomNavigationBar: _buildBottomNav(),
        ),
      ),
    );
  }

  // Home tab 
  Widget _buildHome(BuildContext context, user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          _buildSearchBar(),
          const SizedBox(height: 16),
          const _LiveBannerCarousel(),
          const SizedBox(height: 20),
          _buildReservationSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Header — consistent with admin/organiser 
  Widget _buildHeader(user) {
    final mq   = MediaQuery.of(context);
    final role = user?.role ?? 'student';
    final roleLabel = switch (role) {
      'staff' => 'Staff',
      'admin' => 'Admin',
      _       => 'Student',
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_maroonDark, _maroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, mq.padding.top + 14, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar ring — tap to edit profile
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfilePage()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.55), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFAA3333),
                    child: user?.name.isNotEmpty == true
                        ? Text(
                            user!.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18),
                          )
                        : const Icon(Icons.person_rounded,
                            color: Colors.white, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back,',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                            letterSpacing: 0.2)),
                    Text(
                      user?.name ?? 'Student',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.3),
                      overflow: TextOverflow.ellipsis,
                    ),
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
              // Logout
              _HeaderIconBtn(
                icon: Icons.logout_rounded,
                onTap: () => _signOut(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stat chips — same layout as admin/organiser
          Row(
            children: [
              _HeaderStat(label: 'Role', value: roleLabel),
              const SizedBox(width: 12),
              _HeaderStat(
                  label: 'Email',
                  value: user?.email?.split('@').last ?? '—'),
              const SizedBox(width: 12),
              _HeaderStat(label: 'System', value: 'UTMSports+'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final authVm = context.read<AuthViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            style: FilledButton.styleFrom(backgroundColor: _maroon),
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

  // Search bar 
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _navIndex = 3),
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: Colors.grey.shade400, size: 18),
                    const SizedBox(width: 8),
                    Text('Type here to search booking...',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ViewEventsPage())),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.manage_search_rounded,
                  color: Colors.black87, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // Reservation / Achievement section 
  Widget _buildReservationSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Reservation Record',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (_currentTab == 0) {
                    setState(() => _navIndex = 3);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ViewAchievementsPage()),
                    );
                  }
                },
                child: Text('See all',
                    style: TextStyle(
                        fontSize: 12,
                        color: _maroon,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tabChip('Reservations', 0),
              const SizedBox(width: 12),
              _tabChip('Achievements', 1),
            ],
          ),
          const SizedBox(height: 14),
          if (_currentTab == 0)
            _LiveBookings(
                onSeeAll: () => setState(() => _navIndex = 3))
          else
            _LiveAchievements(
              onSeeAll: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ViewAchievementsPage()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _maroon.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _maroon.withOpacity(0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? _maroon : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  // Bottom nav 
  Widget _buildBottomNav() {
    const items = [
      Icons.home_rounded,
      Icons.event_outlined,
      Icons.add_circle_outline_rounded,
      Icons.confirmation_number_outlined,
      Icons.feedback_outlined,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _navIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _navIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selected
                        ? _maroon.withOpacity(0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(items[i],
                      color: selected ? _maroon : Colors.black54,
                      size: 26),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

//  LIVE BANNER CAROUSEL 
class _LiveBannerCarousel extends StatefulWidget {
  const _LiveBannerCarousel();

  @override
  State<_LiveBannerCarousel> createState() => _LiveBannerCarouselState();
}

class _LiveBannerCarouselState extends State<_LiveBannerCarousel> {
  static const _maroon = Color(0xFF800000);

  static const _categoryColors = <String, Color>{
    'Futsal':          Color(0xFF0A2540),
    'Volleyball':      Color(0xFF1A0A3A),
    'Badminton':       Color(0xFF003D2B),
    'PUBG':            Color(0xFF1A0A00),
    'Mobile Legends':  Color(0xFF2E0A00),
    'Running':         Color(0xFF2D0A2D),
    'Squash':          Color(0xFF002D1A),
    'Table Tennis':    Color(0xFF0A0A2D),
    'Other':           Color(0xFF1A1A2E),
  };

  static const _categoryIcons = <String, IconData>{
    'Futsal':          Icons.sports_soccer,
    'Volleyball':      Icons.sports_volleyball,
    'Badminton':       Icons.sports_tennis,
    'PUBG':            Icons.videogame_asset_rounded,
    'Mobile Legends':  Icons.smartphone_rounded,
    'Running':         Icons.directions_run,
    'Squash':          Icons.sports_handball,
    'Table Tennis':    Icons.sports_tennis,
    'Other':           Icons.emoji_events,
  };

  static const _categoryAccents = <String, Color>{
    'Futsal':          Color(0xFF0369A1),
    'Volleyball':      Color(0xFF7C3AED),
    'Badminton':       Color(0xFF065F46),
    'PUBG':            Color(0xFF92400E),
    'Mobile Legends':  Color(0xFF9A3412),
    'Running':         Color(0xFF800000),
    'Squash':          Color(0xFF065F46),
    'Table Tennis':    Color(0xFF5B21B6),
    'Other':           Color(0xFF374151),
  };

  late final PageController _pageCtrl;
  StreamSubscription<List<EventModel>>? _sub;
  List<EventModel> _events = [];
  bool _loading = true;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe once — never resubscribe on rebuild.
    if (_sub != null) return;
    final vm = context.read<EventViewModel>();
    _sub = vm.allStream.listen((events) {
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
        // Clamp current page index in case events shrink
        if (_current >= events.length && events.isNotEmpty) {
          _current = events.length - 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_events.isEmpty) return _buildEmptyBanner();

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: _events.length,
            itemBuilder: (_, i) => _BannerCard(
              event: _events[i],
              bgColor: _categoryColors[_events[i].category] ??
                  const Color(0xFF1A1A2E),
              accentColor: _categoryAccents[_events[i].category] ??
                  _maroon,
              icon: _categoryIcons[_events[i].category] ??
                  Icons.emoji_events,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_events.length, (i) {
            final active = _current == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? _maroon : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              3,
              (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == 0 ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )),
        ),
      ],
    );
  }

  Widget _buildEmptyBanner() {
    return Container(
      height: 180,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_outlined, color: Colors.white38, size: 36),
            SizedBox(height: 8),
            Text('No events available',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

//  SINGLE BANNER CARD
class _BannerCard extends StatelessWidget {
  final EventModel event;
  final Color bgColor;
  final Color accentColor;
  final IconData icon;

  const _BannerCard({
    required this.event,
    required this.bgColor,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ViewEventsPage()),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [bgColor, Color.lerp(bgColor, accentColor, 0.45)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Faded background sport icon
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(icon,
                    size: 100,
                    color: Colors.white.withOpacity(0.08)),
              ),
            ),
            // Subtle bottom gradient scrim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Category pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25)),
                    ),
                    child: Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8),
                    ),
                  ),
                  const SizedBox(height: 7),
                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Date & location row
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 11, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(event.date,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: Colors.white70),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(event.location,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // "Register" tag — if registration is open
            if (event.registrationOpen)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Open',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//  SHARED HEADER WIDGETS
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
                      shape: BoxShape.circle),
                ),
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

//  LIVE BOOKINGS
class _LiveBookings extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _LiveBookings({required this.onSeeAll});

  static const _maroon = Color(0xFF800000);
  static const _sportIcons = <String, IconData>{
    'Badminton':    Icons.sports_tennis,
    'Table Tennis': Icons.sports_tennis,
    'Volleyball':   Icons.sports_volleyball,
    'Squash':       Icons.sports_handball,
  };
  static const _sportColors = <String, Color>{
    'Badminton':    Color(0xFF800000),
    'Table Tennis': Color(0xFF7C3AED),
    'Volleyball':   Color(0xFF0369A1),
    'Squash':       Color(0xFF065F46),
  };

  String _fmt(String d) {
    try {
      final p  = d.split('-');
      final dt = DateTime(
          int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      const m = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final vm  = context.read<BookingViewModel>();
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return StreamBuilder<List<BookingModel>>(
      stream: vm.watchUserBookings(uid),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(
                    color: _maroon, strokeWidth: 2)),
          );
        }
        final upcoming = (snap.data ?? [])
            .where((b) =>
                b.date.compareTo(today) >= 0 &&
                b.status == 'confirmed')
            .take(3)
            .toList();

        if (upcoming.isEmpty) {
          return _EmptyCard(
            icon: Icons.calendar_today_outlined,
            message: 'No upcoming bookings',
            actionLabel: 'Book a facility',
            onAction: () => context
                .findAncestorStateOfType<_StudentDashboardState>()
                ?.setState(() => context
                    .findAncestorStateOfType<_StudentDashboardState>()!
                    ._navIndex = 2),
          );
        }

        return Column(
          children: upcoming.map((b) {
            final color = _sportColors[b.sport] ?? _maroon;
            final icon  = _sportIcons[b.sport] ?? Icons.sports;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEEEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${b.sport} — Court ${b.court}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('${_fmt(b.date)}  ·  ${b.timeSlot}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _maroon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Upcoming',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _maroon,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

//  LIVE ACHIEVEMENTS
class _LiveAchievements extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _LiveAchievements({required this.onSeeAll});

  static const _maroon = Color(0xFF800000);
  static const _sportIcons = <String, IconData>{
    'Badminton':    Icons.sports_tennis,
    'Running':      Icons.directions_run,
    'Volleyball':   Icons.sports_volleyball,
    'Squash':       Icons.sports_handball,
    'Table Tennis': Icons.sports_tennis,
  };

  Color _awardColor(String a) {
    final s = a.toLowerCase();
    if (s.contains('gold') || s.contains('champion') || s.contains('1st')) {
      return const Color(0xFFB8860B);
    }
    if (s.contains('silver') || s.contains('2nd')) {
      return const Color(0xFF607D8B);
    }
    if (s.contains('bronze') || s.contains('3rd')) {
      return const Color(0xFF8B5E3C);
    }
    return _maroon;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AchievementViewModel>();
    return StreamBuilder<List<AchievementModel>>(
      stream: vm.stream,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(
                    color: _maroon, strokeWidth: 2)),
          );
        }
        final all = (snap.data ?? []).take(2).toList();
        if (all.isEmpty) {
          return const _EmptyCard(
            icon: Icons.emoji_events_outlined,
            message: 'No achievements yet',
          );
        }
        return Column(
          children: all.map((a) {
            final icon  = _sportIcons[a.category] ?? Icons.emoji_events;
            final color = _awardColor(a.award);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEEEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text('${a.studentName}  ·  ${a.date}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.emoji_events,
                                color: color, size: 12),
                            const SizedBox(width: 4),
                            Text(a.award,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

//  EMPTY CARD
class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onAction,
              child: Text(actionLabel!,
                  style: const TextStyle(
                      color: _maroon,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}