import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/booking_model.dart';
import '../../model/event_registration_model.dart';
import '../../viewmodel/booking_viewmodel.dart';
import '../../viewmodel/event_registration_viewmodel.dart';

class ViewBookingPage extends StatelessWidget {
  final bool embedded;
  const ViewBookingPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingViewModel()),
        ChangeNotifierProvider(
            create: (_) => EventRegistrationViewModel()),
      ],
      child: _ViewBookingContent(embedded: embedded),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ViewBookingContent extends StatefulWidget {
  final bool embedded;
  const _ViewBookingContent({required this.embedded});

  @override
  State<_ViewBookingContent> createState() => _ViewBookingContentState();
}

class _ViewBookingContentState extends State<_ViewBookingContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _pillIndex = 0; // 0 = Facility Bookings, 1 = Event Registrations

  static const _maroon     = Color(0xFF800000);
  static const _maroonDark = Color(0xFF5C0000);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final mq  = MediaQuery.of(context);

    final body = Column(
      children: [
        // ── Pill toggle ────────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _TogglePill(
                  label: 'Facility Bookings',
                  icon: Icons.sports_tennis_rounded,
                  selected: _pillIndex == 0,
                  onTap: () => setState(() => _pillIndex = 0),
                ),
                _TogglePill(
                  label: 'Event Registrations',
                  icon: Icons.how_to_reg_rounded,
                  selected: _pillIndex == 1,
                  onTap: () => setState(() => _pillIndex = 1),
                ),
              ],
            ),
          ),
        ),

        // ── Content ────────────────────────────────────────────────────────
        Expanded(
          child: IndexedStack(
            index: _pillIndex,
            children: [
              _FacilityBookingsTab(uid: uid),
              _EventRegistrationsTab(uid: uid),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return Column(
        children: [
          _EmbeddedHeader(
              title: 'My Bookings',
              topPadding: mq.padding.top),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4EFEF),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('My Bookings',
            style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FACILITY BOOKINGS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _FacilityBookingsTab extends StatefulWidget {
  final String uid;
  const _FacilityBookingsTab({required this.uid});

  @override
  State<_FacilityBookingsTab> createState() =>
      _FacilityBookingsTabState();
}

class _FacilityBookingsTabState extends State<_FacilityBookingsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _maroon = Color(0xFF800000);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BookingViewModel>();

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: _maroon,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: _maroon,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<BookingModel>>(
            stream: vm.watchUserBookings(widget.uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: _maroon, strokeWidth: 2));
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              final all = snap.data ?? [];
              final now = DateTime.now();
              final today =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

              final upcoming = all
                  .where((b) =>
                      b.date.compareTo(today) >= 0 &&
                      b.status == 'confirmed')
                  .toList();
              final past = all
                  .where((b) =>
                      b.date.compareTo(today) < 0 ||
                      b.status != 'confirmed')
                  .toList();

              return TabBarView(
                controller: _tab,
                children: [
                  _BookingList(bookings: upcoming, isPast: false),
                  _BookingList(bookings: past, isPast: true),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EVENT REGISTRATIONS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _EventRegistrationsTab extends StatefulWidget {
  final String uid;
  const _EventRegistrationsTab({required this.uid});

  @override
  State<_EventRegistrationsTab> createState() =>
      _EventRegistrationsTabState();
}

class _EventRegistrationsTabState extends State<_EventRegistrationsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  static const _maroon = Color(0xFF800000);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EventRegistrationViewModel>();

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: _maroon,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: _maroon,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Under Review'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EventRegistrationModel>>(
            stream: vm.userRegistrations(widget.uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: _maroon, strokeWidth: 2));
              }

              final all       = snap.data ?? [];
              final confirmed = all
                  .where(
                      (r) => r.status == RegStatus.confirmed)
                  .toList();
              final pending = all
                  .where(
                      (r) => r.status != RegStatus.confirmed)
                  .toList();

              return TabBarView(
                controller: _tab,
                children: [
                  _RegList(items: all),
                  _RegList(
                      items: confirmed,
                      emptyMsg: 'No confirmed registrations yet'),
                  _RegList(
                      items: pending,
                      emptyMsg: 'No pending registrations'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REGISTRATION LIST + CARD
// ─────────────────────────────────────────────────────────────────────────────

class _RegList extends StatelessWidget {
  final List<EventRegistrationModel> items;
  final String emptyMsg;
  const _RegList(
      {required this.items,
      this.emptyMsg = 'No registrations yet'});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_reg_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(emptyMsg,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B6B6B))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _RegCard(reg: items[i]),
    );
  }
}

class _RegCard extends StatefulWidget {
  final EventRegistrationModel reg;
  const _RegCard({required this.reg});

  @override
  State<_RegCard> createState() => _RegCardState();
}

class _RegCardState extends State<_RegCard> {
  bool _expanded = false;

  static const _icons = <String, IconData>{
    'Futsal':         Icons.sports_soccer,
    'Volleyball':     Icons.sports_volleyball,
    'Badminton':      Icons.sports_tennis,
    'PUBG':           Icons.videogame_asset_rounded,
    'Mobile Legends': Icons.smartphone_rounded,
    'Running':        Icons.directions_run,
    'Squash':         Icons.sports_handball,
    'Table Tennis':   Icons.sports_tennis,
    'Other':          Icons.emoji_events,
  };
  static const _colors = <String, Color>{
    'Futsal':         Color(0xFF0369A1),
    'Volleyball':     Color(0xFF800000),
    'Badminton':      Color(0xFF065F46),
    'PUBG':           Color(0xFF5C3D8F),
    'Mobile Legends': Color(0xFF9A3412),
    'Running':        Color(0xFF800000),
    'Squash':         Color(0xFF065F46),
    'Table Tennis':   Color(0xFF7C3AED),
    'Other':          Color(0xFF6B6B6B),
  };

  (Color, Color, IconData) get _statusStyle =>
      switch (widget.reg.status) {
        RegStatus.confirmed => (
            Colors.green.shade700,
            Colors.green.shade50,
            Icons.check_circle_rounded
          ),
        RegStatus.rejected => (
            Colors.red.shade700,
            Colors.red.shade50,
            Icons.cancel_rounded
          ),
        _ => (
            Colors.amber.shade800,
            Colors.amber.shade50,
            Icons.hourglass_empty_rounded
          ),
      };

  @override
  Widget build(BuildContext context) {
    final r                                     = widget.reg;
    final col                                   = _colors[r.eventCategory] ?? const Color(0xFF800000);
    final icon                                  = _icons[r.eventCategory] ?? Icons.emoji_events;
    final (statusColor, statusBg, statusIcon)   = _statusStyle;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: statusColor.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: col.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: col, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.eventTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1A1A1A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 11,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text(r.eventDate,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                            const SizedBox(width: 8),
                            Icon(Icons.people_alt_outlined,
                                size: 11,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text('${r.totalMembers} pax',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Status pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon,
                                  size: 12, color: statusColor),
                              const SizedBox(width: 5),
                              Text(r.status.label,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),

            // ── Expanded details ──────────────────────────────────────────
            if (_expanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1, color: Color(0xFFEDE5E5)),
                    const SizedBox(height: 12),
                    if (r.format != null) ...[
                      _DetailRow(
                          icon: Icons.sports_outlined,
                          label: 'Format',
                          value: r.format!),
                      const SizedBox(height: 8),
                    ],
                    _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Captain',
                        value: r.userName),
                    if (r.teamMembers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DetailRow(
                        icon: Icons.group_outlined,
                        label: 'Members',
                        value: r.teamMembers.join(', '),
                      ),
                    ],
                    if (r.organiserNote != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: statusColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.message_outlined,
                                size: 14, color: statusColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(r.organiserNote!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOOKING LIST + CARD
// ─────────────────────────────────────────────────────────────────────────────

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool isPast;
  const _BookingList(
      {required this.bookings, required this.isPast});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              isPast ? 'No past bookings' : 'No upcoming bookings',
              style: TextStyle(
                  color: Colors.grey.shade400, fontSize: 15),
            ),
            if (!isPast) ...[
              const SizedBox(height: 6),
              Text('Book a facility to get started',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12)),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: bookings.length,
      itemBuilder: (_, i) =>
          _BookingCard(booking: bookings[i], isPast: isPast),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isPast;
  const _BookingCard(
      {required this.booking, required this.isPast});

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

  String get _displayDate {
    try {
      final p = booking.date.split('-');
      if (p.length != 3) return booking.date;
      final dt = DateTime(
          int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      const m = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${m[dt.month]} ${dt.year}';
    } catch (_) {
      return booking.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _sportColors[booking.sport] ?? const Color(0xFF800000);
    final icon = _sportIcons[booking.sport] ?? Icons.sports;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => _BookingDetailSheet(
          booking: booking,
          color: color,
          icon: icon,
          displayDate: _displayDate,
          isPast: isPast,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPast
                ? Colors.grey.shade100
                : color.withOpacity(0.2),
            width: isPast ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: isPast
                        ? Colors.grey.shade100
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon,
                    color:
                        isPast ? Colors.grey.shade400 : color,
                    size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.sport} — Court ${booking.court}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isPast
                              ? Colors.grey.shade500
                              : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 11,
                            color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(_displayDate,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time_rounded,
                            size: 11,
                            color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(booking.timeSlot,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(
                        status: booking.status, isPast: isPast),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  BOOKING DETAIL SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDetailSheet extends StatelessWidget {
  final BookingModel booking;
  final Color color;
  final IconData icon;
  final String displayDate;
  final bool isPast;

  const _BookingDetailSheet({
    required this.booking,
    required this.color,
    required this.icon,
    required this.displayDate,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24,
            MediaQuery.of(context).viewInsets.bottom + 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 14),
            Text('${booking.sport} — Court ${booking.court}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _StatusPill(status: booking.status, isPast: isPast),
            const SizedBox(height: 24),
            _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: displayDate),
            const Divider(height: 20),
            _DetailRow(
                icon: Icons.access_time_rounded,
                label: 'Time Slot',
                value: booking.timeSlot),
            const Divider(height: 20),
            _DetailRow(
                icon: Icons.sports_score_outlined,
                label: 'Sport',
                value: booking.sport),
            const Divider(height: 20),
            _DetailRow(
                icon: Icons.grid_view_rounded,
                label: 'Court',
                value: 'Court ${booking.court}'),
            const Divider(height: 20),
            _DetailRow(
                icon: Icons.email_outlined,
                label: 'Booked by',
                value: booking.userEmail),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _EmbeddedHeader extends StatelessWidget {
  final String title;
  final double topPadding;
  const _EmbeddedHeader(
      {required this.title, required this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5C0000), Color(0xFF800000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding:
          EdgeInsets.fromLTRB(20, topPadding + 14, 20, 18),
      child: Text(title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3)),
    );
  }
}

// Pill toggle button
class _TogglePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TogglePill(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _maroon : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: _maroon.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: selected
                      ? Colors.white
                      : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  final bool isPast;
  const _StatusPill(
      {required this.status, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' when !isPast => (
          const Color(0xFF800000),
          'Upcoming'
        ),
      'confirmed' when isPast  => (
          const Color(0xFF555555),
          'Completed'
        ),
      'cancelled'              => (Colors.red, 'Cancelled'),
      _                        => (
          const Color(0xFF555555),
          'Completed'
        ),
    };
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade500)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// Shared detail row for event registrations
class _DetailRowReg extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRowReg(
      {required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFAAAAAA))),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A))),
          ),
        ],
      );
}