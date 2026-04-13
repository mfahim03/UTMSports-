import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/booking_model.dart';
import '../../model/achievement_model.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/booking_viewmodel.dart';
import '../../viewmodel/achievement_viewmodel.dart';
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
  int _currentBanner = 0;
  int _currentTab = 0;
  int _navIndex = 0;

  static const _maroon = Color(0xFF800000);

  // Banners stay static (events/promotions — can be made dynamic later)
  final List<Map<String, dynamic>> _banners = [
    {
      'title': "UTMCC '24 Run",
      'subtitle': '5KM Finisher',
      'color': Color(0xFF2D0A2D),
      'icon': Icons.directions_run,
    },
    {
      'title': 'Badminton Open',
      'subtitle': 'Register Now',
      'color': Color(0xFF0A1A2D),
      'icon': Icons.sports_tennis,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        ChangeNotifierProvider(create: (_) => AchievementViewModel()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: Builder(builder: (ctx) {
            return IndexedStack(
              index: _navIndex,
              children: [
                _buildHome(ctx, user),
                const ViewAchievementsPage(embedded: true),
                const BookFacilityPage(embedded: true),
                const ViewBookingPage(embedded: true),
                const SubmitFeedbackPage(embedded: true),
              ],
            );
          }),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Home tab ──────────────────────────────────────────────────────────────

  Widget _buildHome(BuildContext context, user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildBannerCarousel(),
          const SizedBox(height: 20),
          _buildReservationSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfilePage()),
            ),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: _maroon.withOpacity(0.3), width: 2),
                color: _maroon.withOpacity(0.08),
              ),
              child: user?.name.isNotEmpty == true
                  ? Center(
                      child: Text(
                        user!.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: _maroon,
                            fontWeight: FontWeight.w800,
                            fontSize: 18),
                      ),
                    )
                  : const Icon(Icons.person_outline_rounded,
                      color: _maroon, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  user?.name ?? 'Student',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.black87, size: 26),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Search bar ────────────────────────────────────────────────────────────

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
                            color: Colors.grey.shade400,
                            fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ViewEventsPage())),
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

  // ── Banner carousel ───────────────────────────────────────────────────────

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            onPageChanged: (i) => setState(() => _currentBanner = i),
            itemCount: _banners.length,
            itemBuilder: (_, i) {
              final b = _banners[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ViewEventsPage())),
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: b['color'] as Color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Icon(b['icon'] as IconData,
                              size: 80,
                              color: Colors.white.withOpacity(0.12)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(b['subtitle'] as String,
                                style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.7),
                                    fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(b['title'] as String,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentBanner == i ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: _currentBanner == i
                    ? _maroon
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Reservation / Achievement section ─────────────────────────────────────

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
                onTap: () => setState(
                    () => _navIndex = _currentTab == 0 ? 3 : 1),
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

          // Live data section
          if (_currentTab == 0)
            _LiveBookings(
              onSeeAll: () => setState(() => _navIndex = 3),
            )
          else
            _LiveAchievements(
              onSeeAll: () => setState(() => _navIndex = 1),
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

  // ── Bottom nav ────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      Icons.home_rounded,
      Icons.emoji_events_rounded,
      Icons.add_circle_outline_rounded,
      Icons.calendar_today_outlined,
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
                  child: Icon(
                    items[i],
                    color: selected ? _maroon : Colors.black54,
                    size: 26,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Live bookings widget (home tab preview) ───────────────────────────────────

class _LiveBookings extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _LiveBookings({required this.onSeeAll});

  static const _maroon = Color(0xFF800000);

  static const _sportIcons = <String, IconData>{
    'Badminton': Icons.sports_tennis,
    'Table Tennis': Icons.sports_tennis,
    'Volleyball': Icons.sports_volleyball,
    'Squash': Icons.sports_handball,
  };

  static const _sportColors = <String, Color>{
    'Badminton': Color(0xFF800000),
    'Table Tennis': Color(0xFF7C3AED),
    'Volleyball': Color(0xFF0369A1),
    'Squash': Color(0xFF065F46),
  };

  String _formatDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length != 3) return dateStr;
      final dt = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final vm = context.read<BookingViewModel>();
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return StreamBuilder<List<BookingModel>>(
      stream: vm.watchUserBookings(uid),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(
                    color: _maroon, strokeWidth: 2)),
          );
        }

        final all = snap.data ?? [];
        // Show only upcoming confirmed, max 2 on home
        final upcoming = all
            .where((b) =>
                b.date.compareTo(todayStr) >= 0 &&
                b.status == 'confirmed')
            .take(3)
            .toList();

        if (upcoming.isEmpty) {
          return _EmptyCard(
            icon: Icons.calendar_today_outlined,
            message: 'No upcoming bookings',
            actionLabel: 'Book a facility',
            onAction: () {
              // Navigate to book tab
              final state = context
                  .findAncestorStateOfType<_StudentDashboardState>();
              state?.setState(() => state._navIndex = 2);
            },
          );
        }

        return Column(
          children: upcoming.map((b) {
            final color =
                _sportColors[b.sport] ?? _maroon;
            final icon =
                _sportIcons[b.sport] ?? Icons.sports;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEEEE),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: color.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${b.sport} — Court ${b.court}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatDate(b.date)}  ·  ${b.timeSlot}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _maroon.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Text('Upcoming',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: _maroon,
                                      fontWeight: FontWeight.w700)),
                            ),
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

// ── Live achievements widget (home tab preview) ───────────────────────────────

class _LiveAchievements extends StatelessWidget {
  final VoidCallback onSeeAll;
  const _LiveAchievements({required this.onSeeAll});

  static const _maroon = Color(0xFF800000);

  static const _sportIcons = <String, IconData>{
    'Badminton': Icons.sports_tennis,
    'Running': Icons.directions_run,
    'Volleyball': Icons.sports_volleyball,
    'Squash': Icons.sports_handball,
    'Table Tennis': Icons.sports_tennis,
  };

  Color _awardColor(String award) {
    final a = award.toLowerCase();
    if (a.contains('gold') || a.contains('champion') || a.contains('1st')) {
      return const Color(0xFFB8860B);
    }
    if (a.contains('silver') || a.contains('2nd')) {
      return const Color(0xFF607D8B);
    }
    if (a.contains('bronze') || a.contains('3rd')) {
      return const Color(0xFF8B5E3C);
    }
    return _maroon;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AchievementViewModel>();

    return StreamBuilder<List<AchievementModel>>(
      stream: vm.stream,
      builder: (ctx, snap) {
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
            final icon =
                _sportIcons[a.category] ?? Icons.emoji_events;
            final awardColor = _awardColor(a.award);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEEEE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: awardColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: awardColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(icon, color: awardColor, size: 22),
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
                        Text(
                          '${a.studentName}  ·  ${a.date}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.emoji_events,
                                color: awardColor, size: 12),
                            const SizedBox(width: 4),
                            Text(a.award,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: awardColor,
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

// ── Empty state card ──────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
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