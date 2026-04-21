import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/event_model.dart';
import '../../model/event_registration_model.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/event_registration_viewmodel.dart';

class EventRegistrationPage extends StatelessWidget {
  final EventModel event;
  const EventRegistrationPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventRegistrationViewModel(),
      child: _RegistrationContent(event: event),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const maroon     = Color(0xFF800000);
  static const maroonDark = Color(0xFF5C0000);
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

// ─────────────────────────────────────────────────────────────────────────────
//  CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _RegistrationContent extends StatefulWidget {
  final EventModel event;
  const _RegistrationContent({required this.event});

  @override
  State<_RegistrationContent> createState() => _RegistrationContentState();
}

class _RegistrationContentState extends State<_RegistrationContent> {
  String? _selectedFormat;
  final List<TextEditingController> _memberCtrl = [];
  final _formKey = GlobalKey<FormState>();

  EventModel get e => widget.event;

  int get _extraSlots   => _memberCtrl.length;
  int get _totalMembers => 1 + _extraSlots;
  int get _maxExtra     => (e.maxPlayers ?? 99) - 1;
  int get _minExtra     => (e.minPlayers - 1).clamp(0, 9999);
  bool get _canAddMore  => _extraSlots < _maxExtra;
  bool get _meetsMinimum => _totalMembers >= e.minPlayers;

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

  Color get _col  => _colors[e.category] ?? _T.maroon;
  IconData get _icon => _icons[e.category] ?? Icons.emoji_events;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _minExtra; i++) {
      _memberCtrl.add(TextEditingController());
    }
    if (e.isBadminton && e.badmintonTypes.isNotEmpty) {
      _selectedFormat = e.badmintonTypes.first;
      _applyBadmintonFormat(_selectedFormat!);
    }
  }

  void _applyBadmintonFormat(String fmt) {
    final needed = switch (fmt) {
      'Solo'   => 0,
      'Double' => 1,
      'Mixed'  => 1,
      _        => 0,
    };
    setState(() {
      while (_memberCtrl.length < needed) {
        _memberCtrl.add(TextEditingController());
      }
      while (_memberCtrl.length > needed) {
        _memberCtrl.removeLast().dispose();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _memberCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  void _addMember() {
    if (_canAddMore) {
      setState(() => _memberCtrl.add(TextEditingController()));
    }
  }

  void _removeMember(int i) {
    setState(() {
      _memberCtrl[i].dispose();
      _memberCtrl.removeAt(i);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_meetsMinimum) {
      _snack(
          'Minimum ${e.minPlayers} player(s) required. Please add more members.',
          isError: true);
      return;
    }
    if (e.isBadminton && _selectedFormat == null) {
      _snack('Please select a format.', isError: true);
      return;
    }

    // Event already passed check
    if (e.isEventPassed) {
      _snack('Registration is closed — this event has already passed.',
          isError: true);
      return;
    }

    final vm = context.read<EventRegistrationViewModel>();

    // Team capacity check
    if (e.maxTeams != null) {
      final confirmedCount = await vm.confirmedTeamCount(e.id);
      if (confirmedCount >= e.maxTeams!) {
        if (!mounted) return;
        _snack('Sorry, all ${e.maxTeams} team slot(s) are full.',
            isError: true);
        return;
      }
    }

    final user   = context.read<AuthViewModel>().currentUser;
    final fbUser = FirebaseAuth.instance.currentUser;
    final members = _memberCtrl.map((c) => c.text.trim()).toList();

    final reg = EventRegistrationModel(
      id: '',
      eventId: e.id,
      eventTitle: e.title,
      eventCategory: e.category,
      eventDate: e.date,
      userId: fbUser?.uid ?? '',
      userName: user?.name ?? fbUser?.displayName ?? 'Unknown',
      userEmail: user?.email ?? fbUser?.email ?? '',
      format: _selectedFormat,
      teamMembers: members,
      totalMembers: _totalMembers,
      registeredAt: DateTime.now(),
    );

    final ok = await vm.submit(reg);
    if (!mounted) return;
    if (ok) {
      _showSuccess();
    } else {
      _snack(vm.error ?? 'Registration failed', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.how_to_reg_rounded,
                  color: Colors.green.shade600, size: 38),
            ),
            const SizedBox(height: 18),
            const Text('Registered!',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Your registration for ${e.title} is under review. The organiser will verify your details.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: _T.textSec, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.maroon,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<EventRegistrationViewModel>();
    final user = context.read<AuthViewModel>().currentUser;

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _col,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Event Registration',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Event banner ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_col.withOpacity(0.9), _col],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: _col.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${e.date}  ·  ${e.location}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            _WhiteChip(label: e.category),
                            _WhiteChip(
                                label: e.maxPlayers != null
                                    ? '${e.minPlayers}–${e.maxPlayers} pax'
                                    : '${e.minPlayers}+ pax'),
                            if (e.maxTeams != null)
                              _WhiteChip(label: '${e.maxTeams} teams max'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Badminton format selector ─────────────────────────────
            if (e.isBadminton && e.badmintonTypes.isNotEmpty) ...[
              _SectionHeader(label: 'Select Format'),
              const SizedBox(height: 10),
              _Card(
                child: Wrap(
                  spacing: 10,
                  children: e.badmintonTypes.map((fmt) {
                    final selected = _selectedFormat == fmt;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedFormat = fmt);
                        _applyBadmintonFormat(fmt);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? _col : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? _col
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(fmt,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: selected
                                    ? Colors.white
                                    : _T.textPri)),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Captain (you) ─────────────────────────────────────────
            _SectionHeader(label: 'Team Captain (You)'),
            const SizedBox(height: 10),
            _Card(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _col.withOpacity(0.12),
                    child: Text(
                      (user?.name.isNotEmpty == true)
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          color: _col,
                          fontWeight: FontWeight.w800,
                          fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'You',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _T.textPri)),
                        Text(user?.email ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: _T.textSec)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _col.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Captain',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _col)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Team members ──────────────────────────────────────────
            if (!e.isBadminton ||
                (_selectedFormat != null &&
                    _selectedFormat != 'Solo')) ...[
              Row(
                children: [
                  _SectionHeader(
                      label:
                          'Team Members${e.maxPlayers != null ? " (max ${e.maxPlayers! - 1} extra)" : ""}'),
                  const Spacer(),
                  if (_canAddMore)
                    GestureDetector(
                      onTap: _addMember,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _col,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Add',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (_memberCtrl.isEmpty)
                _Card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add_outlined,
                          color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 8),
                      Text('Tap "Add" to add team members',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13)),
                    ],
                  ),
                )
              else
                ..._memberCtrl.asMap().entries.map((entry) {
                  final i    = entry.key;
                  final ctrl = entry.value;
                  final isRequired = i < _minExtra;
                  return _MemberField(
                    index: i,
                    controller: ctrl,
                    color: _col,
                    isRequired: isRequired,
                    onRemove: isRequired ? null : () => _removeMember(i),
                  );
                }),
              const SizedBox(height: 6),

              // Player count indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _meetsMinimum
                      ? Colors.green.shade50
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _meetsMinimum
                        ? Colors.green.shade200
                        : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _meetsMinimum
                          ? Icons.check_circle_outline_rounded
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: _meetsMinimum
                          ? Colors.green.shade600
                          : Colors.amber.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _meetsMinimum
                          ? '$_totalMembers player(s) — ready to submit'
                          : '$_totalMembers / ${e.minPlayers} minimum players',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _meetsMinimum
                            ? Colors.green.shade700
                            : Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else
              const SizedBox(height: 8),

            // ── Info notice ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _col.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _col.withOpacity(0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: _col, size: 16),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Registration is open until the event date. Your registration will be reviewed by the organiser. You will see the status update in My Registrations.',
                      style: TextStyle(
                          fontSize: 12,
                          color: _T.textSec,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit button ─────────────────────────────────────────
            SizedBox(
              height: 54,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _col,
                      _T.maroonDark == _col
                          ? const Color(0xFF5C0000)
                          : _col.withBlue(
                              (_col.blue + 30).clamp(0, 255))
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _col.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: vm.busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: vm.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.how_to_reg_rounded,
                                size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Submit Registration',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  MEMBER FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _MemberField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final Color color;
  final bool isRequired;
  final VoidCallback? onRemove;

  const _MemberField({
    required this.index,
    required this.controller,
    required this.color,
    required this.isRequired,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.divider),
        boxShadow: _T.shadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Text('${index + 2}',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                validator: isRequired
                    ? (v) => (v == null || v.trim().isEmpty)
                        ? 'Member name required'
                        : null
                    : null,
                style:
                    const TextStyle(fontSize: 14, color: _T.textPri),
                decoration: InputDecoration(
                  hintText: 'Member ${index + 2} name',
                  hintStyle: const TextStyle(
                      color: _T.textHint, fontSize: 13),
                  border: InputBorder.none,
                  suffixText: isRequired ? '*' : null,
                  suffixStyle: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close_rounded,
                      size: 14, color: Colors.red.shade400),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Text(label,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _T.textHint,
          letterSpacing: 0.6));
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _T.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.divider),
          boxShadow: _T.shadow,
        ),
        child: child,
      );
}

class _WhiteChip extends StatelessWidget {
  final String label;
  const _WhiteChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
      );
}