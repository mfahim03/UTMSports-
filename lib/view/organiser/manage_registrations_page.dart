import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/event_model.dart';
import '../../model/event_registration_model.dart';
import '../../viewmodel/event_registration_viewmodel.dart';

class ManageRegistrationsPage extends StatelessWidget {
  final EventModel event;
  const ManageRegistrationsPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventRegistrationViewModel(),
      child: _ManageRegistrationsContent(event: event),
    );
  }
}

class _T {
  static const maroon     = Color(0xFF800000);
  static const bg         = Color(0xFFF4EFEF);
  static const surface    = Color(0xFFFFFFFF);
  static const divider    = Color(0xFFEDE5E5);
  static const textPri    = Color(0xFF1A1A1A);
  static const textSec    = Color(0xFF6B6B6B);
  static const textHint   = Color(0xFFAAAAAA);
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

class _ManageRegistrationsContent extends StatefulWidget {
  final EventModel event;
  const _ManageRegistrationsContent({required this.event});

  @override
  State<_ManageRegistrationsContent> createState() =>
      _ManageRegistrationsContentState();
}

class _ManageRegistrationsContentState
    extends State<_ManageRegistrationsContent>
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

  EventModel get e => widget.event;

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

  Color get _col => _colors[e.category] ?? _T.maroon;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventRegistrationViewModel>();

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _col,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrations',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            Text(e.title,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.75))),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Under Review'),
              Tab(text: 'Confirmed'),
            ],
          ),
        ),
      ),
      body: StreamBuilder<List<EventRegistrationModel>>(
        stream: vm.eventRegistrations(e.id),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _T.maroon, strokeWidth: 2.5));
          }
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(
                        color: _T.textSec)));
          }

          final all     = snap.data ?? [];
          final pending = all
              .where((r) => r.status == RegStatus.pending)
              .toList();
          final confirmed = all
              .where((r) => r.status == RegStatus.confirmed)
              .toList();

          return Column(
            children: [
              // Stats banner
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Row(
                  children: [
                    _StatBadge(
                        count: all.length,
                        label: 'Total',
                        color: _col),
                    const SizedBox(width: 10),
                    _StatBadge(
                        count: pending.length,
                        label: 'Pending',
                        color: Colors.amber.shade700),
                    const SizedBox(width: 10),
                    _StatBadge(
                        count: confirmed.length,
                        label: 'Confirmed',
                        color: Colors.green.shade600),
                    const SizedBox(width: 10),
                    _StatBadge(
                        count: all
                            .where((r) =>
                                r.status == RegStatus.rejected)
                            .length,
                        label: 'Rejected',
                        color: Colors.red.shade600),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _RegistrationList(
                        items: all, vm: vm, eventCol: _col),
                    _RegistrationList(
                        items: pending,
                        vm: vm,
                        eventCol: _col,
                        emptyMsg: 'No pending registrations'),
                    _RegistrationList(
                        items: confirmed,
                        vm: vm,
                        eventCol: _col,
                        emptyMsg: 'No confirmed registrations'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

//  STAT BADGE
class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _StatBadge(
      {required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      );
}

//  LIST
class _RegistrationList extends StatelessWidget {
  final List<EventRegistrationModel> items;
  final EventRegistrationViewModel vm;
  final Color eventCol;
  final String emptyMsg;

  const _RegistrationList({
    required this.items,
    required this.vm,
    required this.eventCol,
    this.emptyMsg = 'No registrations',
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: eventCol.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.how_to_reg_outlined,
                  color: eventCol, size: 32),
            ),
            const SizedBox(height: 14),
            Text(emptyMsg,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _T.textSec)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: items.length,
      itemBuilder: (_, i) => _RegistrationCard(
        reg: items[i],
        vm: vm,
        eventCol: eventCol,
      ),
    );
  }
}

//  REGISTRATION CARD (organiser view — expandable + verify actions)
class _RegistrationCard extends StatefulWidget {
  final EventRegistrationModel reg;
  final EventRegistrationViewModel vm;
  final Color eventCol;
  const _RegistrationCard(
      {required this.reg, required this.vm, required this.eventCol});

  @override
  State<_RegistrationCard> createState() => _RegistrationCardState();
}

class _RegistrationCardState extends State<_RegistrationCard> {
  bool _expanded = false;
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _handleAction(RegStatus newStatus) async {
    final note = _noteCtrl.text.trim().isEmpty
        ? null
        : _noteCtrl.text.trim();
    final ok = await widget.vm.updateStatus(
        widget.reg.id, newStatus,
        note: note);
    if (!mounted) return;
    if (ok) {
      setState(() => _expanded = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newStatus == RegStatus.confirmed
            ? 'Registration confirmed ✓'
            : 'Registration rejected'),
        backgroundColor: newStatus == RegStatus.confirmed
            ? Colors.green.shade700
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reg;
    final col = widget.eventCol;
    final (statusColor, statusBg, statusIcon) = _statusStyle;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: statusColor.withOpacity(0.2), width: 1.5),
        boxShadow: _T.shadow,
      ),
      child: Column(
        children: [
          // Header 
          InkWell(
            borderRadius:
                BorderRadius.circular(18),
            onTap: () =>
                setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: col.withOpacity(0.1),
                    child: Text(
                      r.userName.isNotEmpty
                          ? r.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: col,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(r.userName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _T.textPri)),
                        const SizedBox(height: 2),
                        Text(r.userEmail,
                            style: const TextStyle(
                                fontSize: 11,
                                color: _T.textSec)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3),
                              decoration: BoxDecoration(
                                color: statusBg,
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: statusColor
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon,
                                      size: 10,
                                      color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(r.status.label,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: statusColor)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.people_alt_outlined,
                                size: 11,
                                color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text('${r.totalMembers} pax',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _T.textSec)),
                            if (r.format != null) ...[
                              const SizedBox(width: 6),
                              Text('· ${r.format}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _T.textSec)),
                            ],
                          ],
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
          ),

          // Expanded: members + actions 
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(
                      height: 1, color: _T.divider),
                  const SizedBox(height: 12),

                  // Captain row
                  _MemberRow(
                      name: r.userName,
                      label: 'Captain',
                      color: col),
                  const SizedBox(height: 6),

                  // Extra members
                  ...r.teamMembers.asMap().entries.map(
                        (e) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 6),
                          child: _MemberRow(
                            name: e.value,
                            label: 'Member ${e.key + 2}',
                            color: col,
                          ),
                        ),
                      ),

                  const SizedBox(height: 12),

                  // Note field
                  TextField(
                    controller: _noteCtrl,
                    style: const TextStyle(
                        fontSize: 13, color: _T.textPri),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Optional note to participant…',
                      hintStyle: const TextStyle(
                          fontSize: 12,
                          color: _T.textHint),
                      filled: true,
                      fillColor: const Color(0xFFF4EFEF),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _T.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _T.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _T.maroon, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action buttons
                  if (r.status != RegStatus.confirmed &&
                      r.status != RegStatus.rejected) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _ActionBtn(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            color: Colors.red.shade600,
                            bg: Colors.red.shade50,
                            onTap: () => _handleAction(
                                RegStatus.rejected),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _ActionBtn(
                            label: 'Confirm Registration',
                            icon: Icons.check_rounded,
                            color: Colors.white,
                            bg: Colors.green.shade600,
                            filled: true,
                            onTap: () => _handleAction(
                                RegStatus.confirmed),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Allow re-toggle
                    Row(
                      children: [
                        if (r.status == RegStatus.confirmed)
                          Expanded(
                            child: _ActionBtn(
                              label: 'Revoke Confirmation',
                              icon: Icons.undo_rounded,
                              color: Colors.amber.shade700,
                              bg: Colors.amber.shade50,
                              onTap: () => _handleAction(
                                  RegStatus.pending),
                            ),
                          ),
                        if (r.status == RegStatus.rejected)
                          Expanded(
                            child: _ActionBtn(
                              label: 'Restore to Pending',
                              icon: Icons.undo_rounded,
                              color: Colors.amber.shade700,
                              bg: Colors.amber.shade50,
                              onTap: () => _handleAction(
                                  RegStatus.pending),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

//  MEMBER ROW
class _MemberRow extends StatelessWidget {
  final String name;
  final String label;
  final Color color;
  const _MemberRow(
      {required this.name, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4EFEF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.textPri)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ],
        ),
      );
}

//  ACTION BUTTON
class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool filled;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: filled
                ? null
                : Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ],
          ),
        ),
      );
}