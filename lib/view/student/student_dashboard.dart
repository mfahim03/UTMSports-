import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodel/auth_viewmodel.dart';
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
  int _currentTab = 0; // 0 = Reservations, 1 = Achievements
  int _navIndex = 0;

  static const _maroon = Color(0xFF800000);

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'UTMCC \'24 Run',
      'subtitle': '5KM Finisher',
      'color': Color(0xFF2D0A2D),
    },
    {
      'title': 'Badminton Open',
      'subtitle': 'Register Now',
      'color': Color(0xFF0A1A2D),
    },
  ];

  final List<Map<String, dynamic>> _reservations = [
    {
      'icon': Icons.sports_tennis,
      'title': 'Badminton Court Indoor\nFacilities - Court 8',
      'date': '17 Nov 2025, 16:50–18:50',
      'status': 'To be check in',
      'statusColor': Color(0xFF800000),
    },
    {
      'icon': Icons.sports_volleyball,
      'title': 'Volleyball Court\nOutdoor - Court 2',
      'date': '20 Nov 2025, 08:00–10:00',
      'status': 'Confirmed',
      'statusColor': Color(0xFF2E7D32),
    },
  ];

  final List<Map<String, dynamic>> _achievements = [
    {
      'icon': Icons.emoji_events,
      'title': 'UTMCC Run 2024\n5KM Finisher',
      'date': '10 Oct 2024',
      'status': 'Gold Medal',
      'statusColor': Color(0xFFB8860B),
    },
    {
      'icon': Icons.sports_tennis,
      'title': 'Badminton Inter-Faculty\nMens Singles',
      'date': '5 Sep 2024',
      'status': 'Champion',
      'statusColor': Color(0xFF800000),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: IndexedStack(
          index: _navIndex,
          children: [
            _buildHome(user),
            const ViewAchievementsPage(embedded: true),
            const BookFacilityPage(embedded: true),
            const ViewBookingPage(embedded: true),
            const SubmitFeedbackPage(embedded: true),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Home tab ────────────────────────────────────────────────────────────────

  Widget _buildHome(user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(user),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildBannerCarousel(),
          const SizedBox(height: 20),
          _buildReservationSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

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
                border:
                    Border.all(color: _maroon.withOpacity(0.3), width: 2),
                color: _maroon.withOpacity(0.08),
              ),
              child: const Icon(Icons.person_outline_rounded,
                  color: _maroon, size: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  user?.name ?? 'Student',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.black87, size: 26),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                      color: _maroon, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ViewBookingPage())),
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

  // ── Banner carousel ─────────────────────────────────────────────────────────

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
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ViewEventsPage())),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
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
                          child: Icon(Icons.emoji_events_rounded,
                              size: 80,
                              color: Colors.white.withOpacity(0.15)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(b['subtitle'] as String,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
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
                color:
                    _currentBanner == i ? _maroon : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Reservation / Achievement section ──────────────────────────────────────

  Widget _buildReservationSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reservation Record',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(
            children: [
              _tabChip('Reservations', 0),
              const SizedBox(width: 12),
              _tabChip('Achievements', 1),
            ],
          ),
          const SizedBox(height: 14),
          ...(_currentTab == 0 ? _reservations : _achievements)
              .map((item) => _recordCard(item)),
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
          color:
              selected ? _maroon.withOpacity(0.12) : Colors.transparent,
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

  Widget _recordCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEEEE),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _maroon.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'] as IconData,
                color: _maroon, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] as String,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 2),
                const SizedBox(height: 3),
                Text(item['date'] as String,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(item['status'] as String,
                        style: TextStyle(
                            fontSize: 12,
                            color: item['statusColor'] as Color,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded,
                        size: 12,
                        color: item['statusColor'] as Color),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom nav ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      Icons.home_rounded,
      Icons.emoji_events_rounded,
      Icons.add_circle_outline_rounded,
      Icons.calendar_today_outlined,
      Icons.bookmark_outline_rounded,
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