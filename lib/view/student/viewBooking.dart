import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/booking_model.dart';
import '../../viewmodel/booking_viewmodel.dart';

class ViewBookingPage extends StatelessWidget {
  final bool embedded;
  const ViewBookingPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(),
      child: _ViewBookingContent(embedded: embedded),
    );
  }
}

class _ViewBookingContent extends StatefulWidget {
  final bool embedded;
  const _ViewBookingContent({required this.embedded});

  @override
  State<_ViewBookingContent> createState() => _ViewBookingContentState();
}

class _ViewBookingContentState extends State<_ViewBookingContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  static const _maroon     = Color(0xFF800000);

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
    final vm  = context.read<BookingViewModel>();
    final mq  = MediaQuery.of(context);

    final tabsAndContent = Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: _maroon,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: _maroon,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<List<BookingModel>>(
            stream: vm.watchUserBookings(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: _maroon));
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              final all = snap.data ?? [];
              final now = DateTime.now();
              final todayStr =
                  '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

              final upcoming = all
                  .where((b) => b.date.compareTo(todayStr) >= 0 && b.status == 'confirmed')
                  .toList();
              final past = all
                  .where((b) => b.date.compareTo(todayStr) < 0 || b.status != 'confirmed')
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

    if (widget.embedded) {
      return Column(
        children: [
          _EmbeddedHeader(title: 'My Booking', topPadding: mq.padding.top),
          Expanded(child: tabsAndContent),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: tabsAndContent,
    );
  }
}

// EMBEDDED HEADER
class _EmbeddedHeader extends StatelessWidget {
  final String title;
  final double topPadding;
  const _EmbeddedHeader({required this.title, required this.topPadding});

  static const _maroon     = Color(0xFF800000);
  static const _maroonDark = Color(0xFF5C0000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_maroonDark, _maroon], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 18),
      child: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
    );
  }
}

// BOOKING LIST
class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool isPast;
  const _BookingList({required this.bookings, required this.isPast});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(isPast ? 'No past bookings' : 'No upcoming bookings',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
            if (!isPast) ...[
              const SizedBox(height: 6),
              Text('Book a facility to get started',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _BookingCard(booking: bookings[i], isPast: isPast),
    );
  }
}

// BOOKING CARD
class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isPast;
  const _BookingCard({required this.booking, required this.isPast});

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
      final parts = booking.date.split('-');
      if (parts.length != 3) return booking.date;
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return booking.date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _sportColors[booking.sport] ?? const Color(0xFF800000);
    final icon  = _sportIcons[booking.sport] ?? Icons.sports;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        // isScrollControlled lets the sheet expand to fit content
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
            color: isPast ? Colors.grey.shade100 : color.withOpacity(0.2),
            width: isPast ? 1 : 1.5,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                    color: isPast ? Colors.grey.shade100 : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: isPast ? Colors.grey.shade400 : color, size: 26),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${booking.sport} — Court ${booking.court}',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14,
                          color: isPast ? Colors.grey.shade500 : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(_displayDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        const SizedBox(width: 10),
                        Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(booking.timeSlot,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(status: booking.status, isPast: isPast),
                  ],
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// BOOKING DETAIL SHEET
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
          24,
          20,
          24,
          // Extra padding so content clears the bottom of the screen
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),

            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 14),

            Text('${booking.sport} — Court ${booking.court}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _StatusPill(status: booking.status, isPast: isPast),
            const SizedBox(height: 24),

            _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: displayDate),
            const Divider(height: 20),
            _DetailRow(icon: Icons.access_time_rounded, label: 'Time Slot', value: booking.timeSlot),
            const Divider(height: 20),
            _DetailRow(icon: Icons.sports_score_outlined, label: 'Sport', value: booking.sport),
            const Divider(height: 20),
            _DetailRow(icon: Icons.grid_view_rounded, label: 'Court', value: 'Court ${booking.court}'),
            const Divider(height: 20),
            _DetailRow(icon: Icons.email_outlined, label: 'Booked by', value: booking.userEmail),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SHARED WIDGETS
class _StatusPill extends StatelessWidget {
  final String status;
  final bool isPast;
  const _StatusPill({required this.status, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'confirmed' when !isPast => (const Color(0xFF800000), 'Upcoming'),
      'confirmed' when isPast  => (const Color(0xFF555555), 'Completed'),
      'cancelled'              => (Colors.red, 'Cancelled'),
      _                        => (const Color(0xFF555555), 'Completed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const Spacer(),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}