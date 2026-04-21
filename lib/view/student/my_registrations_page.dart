import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/event_registration_model.dart';
import '../../viewmodel/event_registration_viewmodel.dart';

class MyRegistrationsPage extends StatelessWidget {
  final bool embedded;
  const MyRegistrationsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventRegistrationViewModel(),
      child: _MyRegistrationsContent(embedded: embedded),
    );
  }
}

class _MyRegistrationsContent extends StatefulWidget {
  final bool embedded;
  const _MyRegistrationsContent({required this.embedded});

  @override
  State<_MyRegistrationsContent> createState() =>
      _MyRegistrationsContentState();
}

class _MyRegistrationsContentState
    extends State<_MyRegistrationsContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

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

  static const _maroon = Color(0xFF800000);
  static const _bg     = Color(0xFFF4EFEF);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final vm  = context.read<EventRegistrationViewModel>();

    final body = Column(
      children: [
        // Tab bar
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            labelColor: _maroon,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: _maroon,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Confirmed'),
              Tab(text: 'Under Review'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<EventRegistrationModel>>(
            stream: vm.userRegistrations(uid),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: _maroon, strokeWidth: 2));
              }
              final all         = snap.data ?? [];
              final confirmed   = all.where((r) => r.status == RegStatus.confirmed).toList();
              final underReview = all.where((r) => r.status != RegStatus.confirmed).toList();

              return TabBarView(
                controller: _tab,
                children: [
                  _RegList(registrations: all, vm: vm),
                  _RegList(registrations: confirmed, vm: vm,
                      emptyMsg: 'No confirmed registrations yet'),
                  _RegList(registrations: underReview, vm: vm,
                      emptyMsg: 'No pending registrations'),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Registrations',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: body,
    );
  }
}

//  LIST
class _RegList extends StatelessWidget {
  final List<EventRegistrationModel> registrations;
  final EventRegistrationViewModel vm;
  final String emptyMsg;

  const _RegList({
    required this.registrations,
    required this.vm,
    this.emptyMsg = 'No registrations yet',
  });

  @override
  Widget build(BuildContext context) {
    if (registrations.isEmpty) {
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
      itemCount: registrations.length,
      itemBuilder: (_, i) =>
          _RegCard(reg: registrations[i], vm: vm),
    );
  }
}

//  REGISTRATION CARD
class _RegCard extends StatefulWidget {
  final EventRegistrationModel reg;
  final EventRegistrationViewModel vm;
  const _RegCard({required this.reg, required this.vm});

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
    final r   = widget.reg;
    final col = _colors[r.eventCategory] ?? const Color(0xFF800000);
    final icon = _icons[r.eventCategory] ?? Icons.emoji_events;
    final (statusColor, statusBg, statusIcon) = _statusStyle;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: statusColor.withOpacity(0.25),
            width: 1.5,
          ),
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
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B6B6B))),
                            const SizedBox(width: 8),
                            Icon(Icons.people_alt_outlined,
                                size: 11,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 4),
                            Text('${r.totalMembers} pax',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B6B6B))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    statusColor.withOpacity(0.3)),
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

            // Expanded details
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
                                      fontWeight:
                                          FontWeight.w500)),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

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