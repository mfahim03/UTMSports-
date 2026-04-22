import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/event_model.dart';
import '../../viewmodel/event_viewmodel.dart';
import '../../viewmodel/event_registration_viewmodel.dart';
import 'event_registration_page.dart';

class ViewEventsPage extends StatelessWidget {
  final bool embedded;
  const ViewEventsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventViewModel()),
        ChangeNotifierProvider(
            create: (_) => EventRegistrationViewModel()),
      ],
      child: _ViewEventsContent(embedded: embedded),
    );
  }
}

class _ViewEventsContent extends StatelessWidget {
  final bool embedded;
  const _ViewEventsContent({required this.embedded});

  static const _maroon = Color(0xFF800000);
  static const _bg     = Color(0xFFF4EFEF);

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

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EventViewModel>();
    final mq = MediaQuery.of(context);

    final listBody = StreamBuilder<List<EventModel>>(
      stream: vm.allStream,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  color: _maroon, strokeWidth: 2));
        }
        if (snap.hasError) {
          return _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load events',
            subtitle: '${snap.error}',
          );
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const _EmptyState(
            icon: Icons.event_outlined,
            title: 'No events yet',
            subtitle: 'Check back soon for upcoming sports events',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: list.length,
          itemBuilder: (_, i) => _EventCard(
            event: list[i],
            color: _colors[list[i].category] ?? _maroon,
            icon: _icons[list[i].category] ?? Icons.emoji_events,
          ),
        );
      },
    );

    if (embedded) {
      return Column(
        children: [
          _EmbeddedHeader(
              title: 'Sports Events', topPadding: mq.padding.top),
          Expanded(child: listBody),
        ],
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Sports Events',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: listBody,
    );
  }
}

// ── EMBEDDED HEADER ───────────────────────────────────────────────────────────
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
        gradient: LinearGradient(
          colors: [_maroonDark, _maroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 18),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

// ── EVENT CARD ────────────────────────────────────────────────────────────────
class _EventCard extends StatefulWidget {
  final EventModel event;
  final Color color;
  final IconData icon;
  const _EventCard(
      {required this.event, required this.color, required this.icon});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e   = widget.event;
    final col = widget.color;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Date display (supports date range)
    final dateLabel = e.isMultiDay
        ? '${e.date}'          // already formatted as range in model
        : e.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.withOpacity(0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: col.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Card header ─────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: col.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: col.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: col, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            e.isMultiDay
                                ? Icons.date_range_outlined
                                : Icons.calendar_today_outlined,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$dateLabel  ·  ${e.location}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _expanded = !_expanded),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // ── Chips row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _Chip(label: e.category, color: col),
                const SizedBox(width: 8),
                _Chip(
                  label: e.maxPlayers != null
                      ? '${e.minPlayers}–${e.maxPlayers} pax'
                      : '${e.minPlayers}+ pax',
                  color: const Color(0xFF0A7A5A),
                ),
                if (e.isBadminton && e.badmintonTypes.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _Chip(
                    label: e.badmintonTypes.join(' · '),
                    color: const Color(0xFF7C3AED),
                  ),
                ],
                const Spacer(),
                if (!e.registrationOpen)
                  _Chip(label: 'Closed', color: Colors.grey),
              ],
            ),
          ),

          // ── Expanded section ─────────────────────────────────────────
          if (_expanded) ...[
            if (e.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  e.description!,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.5),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: e.registrationOpen
                  ? _RegistrationButton(event: e, col: col, uid: uid)
                  : _ClosedButton(),
            ),
          ] else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Registration button with full / already-registered / open states ──────────
class _RegistrationButton extends StatelessWidget {
  final EventModel event;
  final Color col;
  final String uid;

  const _RegistrationButton({
    required this.event,
    required this.col,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EventRegistrationViewModel>();

    return FutureBuilder<List<Object>>(
      future: Future.wait([
        vm.isRegistered(event.id, uid),
        vm.confirmedTeamCount(event.id),
      ]),
      builder: (_, snap) {
        final already    = (snap.data?[0] as bool?) ?? false;
        final confirmed  = (snap.data?[1] as int?) ?? 0;
        final isFull     = event.maxTeams != null &&
            confirmed >= event.maxTeams!;

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: already
              // Already registered
              ? Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 8),
                      Text('Already Registered',
                          style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                )
              : isFull
                  // Slots full
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              color: Colors.orange.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Full — ${event.maxTeams} teams registered',
                            style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  // Open for registration
                  : ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EventRegistrationPage(event: event),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: col,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.how_to_reg_rounded,
                          size: 18),
                      label: Text(
                        event.maxTeams != null
                            ? 'Register Now  (${event.maxTeams! - confirmed} slots left)'
                            : 'Register Now',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
        );
      },
    );
  }
}

class _ClosedButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('Registration Closed',
            style: TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B6B6B))),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}