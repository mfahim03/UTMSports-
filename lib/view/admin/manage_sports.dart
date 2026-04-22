// lib/view/admin/manage_sports_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../model/sport_config_model.dart';
import '../../repository/sport_repository.dart';

// ── Design tokens (matching admin_page.dart) ─────────────────────────────────
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

// ── Entry point ───────────────────────────────────────────────────────────────
class ManageSportsPage extends StatelessWidget {
  const ManageSportsPage({super.key});

  @override
  Widget build(BuildContext context) => const _ManageSportsContent();
}

class _ManageSportsContent extends StatelessWidget {
  const _ManageSportsContent();

  final _repo = const _RepoHolder();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_T.maroonDark, _T.maroon],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.fromLTRB(16, mq.padding.top + 10, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Manage Sports',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3)),
                        SizedBox(height: 2),
                        Text('Add, edit or remove sports & courts',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Info banner ───────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFCC02), width: 1),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFB45309), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sports in the same Court Group share physical courts. '
                      'Setting "Physical courts per booking" to 2 means 1 '
                      'court of that sport uses 2 physical courts (e.g. '
                      'Volleyball = 2 × Badminton courts).',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          height: 1.45),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sport list ────────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<List<SportConfig>>(
                stream: SportRepository().watchAllSports(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _T.maroon));
                  }
                  final sports = snap.data ?? [];
                  if (sports.isEmpty) {
                    return _EmptyState(
                        onAdd: () => _openEditor(context, null));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: sports.length,
                    itemBuilder: (_, i) => _SportCard(
                      sport: sports[i],
                      onEdit:   () => _openEditor(context, sports[i]),
                      onDelete: () => _confirmDelete(context, sports[i]),
                      onToggle: (val) => SportRepository()
                          .setActive(sports[i].id, active: val),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // ── FAB ───────────────────────────────────────────────────────────
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, null),
          backgroundColor: _T.maroon,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Sport',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, SportConfig? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SportEditorSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, SportConfig sport) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Sport',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Remove "${sport.name}" from the booking system? '
            'Existing bookings are not affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await SportRepository().delete(sport.id);
  }
}

// Workaround: const classes can't have instance fields; use a helper
class _RepoHolder {
  const _RepoHolder();
}

// ── Sport card ────────────────────────────────────────────────────────────────
class _SportCard extends StatelessWidget {
  final SportConfig sport;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _SportCard({
    required this.sport,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.divider),
        boxShadow: _T.shadow,
      ),
      child: Column(
        children: [
          // ── Top row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                // Icon chip
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sport.isActive
                        ? _T.maroonFade
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _sportIcon(sport.name),
                    color: sport.isActive ? _T.maroon : Colors.grey.shade400,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sport.name,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: sport.isActive
                                  ? _T.textPrimary
                                  : _T.textHint)),
                      const SizedBox(height: 2),
                      Text(
                        sport.isDedicated
                            ? 'Dedicated courts (${sport.courtGroup})'
                            : 'Shared hall: ${sport.courtGroup}',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: sport.isDedicated
                                ? const Color(0xFF065F46)
                                : const Color(0xFF0369A1)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: sport.isActive,
                  onChanged: onToggle,
                  activeColor: _T.maroon,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),

          // ── Stats row ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _Chip(
                    icon: Icons.crop_square_rounded,
                    label: '${sport.courtCount} courts'),
                const SizedBox(width: 8),
                _Chip(
                    icon: Icons.layers_rounded,
                    label:
                        '${sport.physicalCourtsPerLogicalCourt}× physical'),
                const SizedBox(width: 8),
                _Chip(
                    icon: Icons.schedule_rounded,
                    label: '${sport.timeSlots.length} slots'),
              ],
            ),
          ),

          // ── Divider + actions ─────────────────────────────────────────
          Container(
            height: 1,
            color: _T.divider,
          ),
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: _T.maroon,
                  onTap: onEdit,
                ),
              ),
              Container(width: 1, height: 44, color: _T.divider),
              Expanded(
                child: _ActionBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: Colors.red.shade600,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sport editor bottom sheet ─────────────────────────────────────────────────
class _SportEditorSheet extends StatefulWidget {
  final SportConfig? existing;
  const _SportEditorSheet({this.existing});

  @override
  State<_SportEditorSheet> createState() => _SportEditorSheetState();
}

class _SportEditorSheetState extends State<_SportEditorSheet> {
  final _repo = SportRepository();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _groupCtrl;
  late final TextEditingController _slotCtrl;

  // State
  late int _courtCount;
  late int _physicalMultiplier;
  late bool _isDedicated;
  late List<String> _timeSlots;
  bool _saving = false;
  Set<String> _existingGroups = {};

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _nameCtrl  = TextEditingController(text: s?.name ?? '');
    _groupCtrl = TextEditingController(
        text: s != null && !s.isDedicated ? s.courtGroup : '');
    _slotCtrl  = TextEditingController();
    _courtCount        = s?.courtCount ?? 2;
    _physicalMultiplier = s?.physicalCourtsPerLogicalCourt ?? 1;
    _isDedicated       = s?.isDedicated ?? false;
    _timeSlots         = List<String>.from(s?.timeSlots ?? []);
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _repo.fetchAllGroups();
      if (mounted) setState(() => _existingGroups = groups);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _groupCtrl.dispose();
    _slotCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_timeSlots.isEmpty) {
      _showErr('Add at least one time slot.');
      return;
    }

    setState(() => _saving = true);
    try {
      final group = _isDedicated
          ? _nameCtrl.text.trim()     // unique group = sport name
          : (_groupCtrl.text.trim().isEmpty
              ? 'Main Hall'
              : _groupCtrl.text.trim());

      final config = SportConfig(
        id:        widget.existing?.id ?? '',
        name:      _nameCtrl.text.trim(),
        courtGroup: group,
        physicalCourtsPerLogicalCourt: _isDedicated ? 1 : _physicalMultiplier,
        courtCount: _courtCount,
        timeSlots:  _timeSlots,
        isActive:   widget.existing?.isActive ?? true,
      );

      await _repo.save(config);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      _showErr(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _addSlot() {
    final v = _slotCtrl.text.trim();
    if (v.isEmpty) return;
    if (_timeSlots.contains(v)) {
      _showErr('That slot already exists.');
      return;
    }
    setState(() {
      _timeSlots.add(v);
      _slotCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isEdit = widget.existing != null;

    return Container(
      margin: EdgeInsets.only(top: mq.padding.top + 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),

          // Title bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(isEdit ? 'Edit Sport' : 'New Sport',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _T.textPrimary)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: _T.textSecond),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _T.divider),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, mq.viewInsets.bottom + 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Sport name ─────────────────────────────────────
                    _Label('Sport Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: _inputDec('e.g. Futsal'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? 'Enter a sport name'
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Court type ─────────────────────────────────────
                    _Label('Court Type'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TypeChip(
                          label: 'Shared Hall',
                          icon: Icons.people_alt_rounded,
                          selected: !_isDedicated,
                          onTap: () =>
                              setState(() => _isDedicated = false),
                        ),
                        const SizedBox(width: 10),
                        _TypeChip(
                          label: 'Dedicated',
                          icon: Icons.lock_outline_rounded,
                          selected: _isDedicated,
                          onTap: () =>
                              setState(() => _isDedicated = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isDedicated
                          ? 'This sport has its own courts — '
                            'no conflicts with other sports.'
                          : 'Shares physical courts with other '
                            '"Shared Hall" sports in the same group.',
                      style: const TextStyle(
                          fontSize: 11.5, color: _T.textSecond),
                    ),
                    const SizedBox(height: 20),

                    // ── Court group (only for shared) ──────────────────
                    if (!_isDedicated) ...[
                      _Label('Court Group Name'),
                      const SizedBox(height: 8),
                      // Suggestions
                      if (_existingGroups.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: _existingGroups
                              .where((g) => g != _nameCtrl.text.trim())
                              .map((g) => ActionChip(
                                    label: Text(g,
                                        style: const TextStyle(fontSize: 12)),
                                    onPressed: () => setState(
                                        () => _groupCtrl.text = g),
                                    backgroundColor:
                                        _groupCtrl.text == g
                                            ? _T.maroonFade
                                            : Colors.grey.shade100,
                                    side: BorderSide(
                                        color: _groupCtrl.text == g
                                            ? _T.maroon
                                            : Colors.grey.shade300),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      TextFormField(
                        controller: _groupCtrl,
                        decoration: _inputDec(
                            'e.g. Main Hall (leave blank for "Main Hall")'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sports with the same group name share courts. '
                        'Booking one will block overlapping courts in others.',
                        style:
                            TextStyle(fontSize: 11.5, color: _T.textSecond),
                      ),
                      const SizedBox(height: 20),

                      // ── Physical courts per booking ────────────────
                      _Label('Physical Courts per Booking'),
                      const SizedBox(height: 4),
                      Text(
                        'How many physical courts does 1 booking of this '
                        'sport occupy in the shared hall?\n'
                        'Badminton = 1  •  Volleyball = 2  •  Futsal = 4',
                        style: const TextStyle(
                            fontSize: 11.5, color: _T.textSecond),
                      ),
                      const SizedBox(height: 12),
                      _Stepper(
                        value: _physicalMultiplier,
                        min: 1,
                        max: 8,
                        onChanged: (v) =>
                            setState(() => _physicalMultiplier = v),
                        label: 'physical court(s)',
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Court count ────────────────────────────────────
                    _Label('Number of Courts'),
                    const SizedBox(height: 4),
                    if (!_isDedicated)
                      Text(
                        'Total physical courts used = '
                        '${_courtCount * _physicalMultiplier}  '
                        '($_courtCount courts × $_physicalMultiplier physical each)',
                        style: const TextStyle(
                            fontSize: 11.5, color: _T.textSecond),
                      ),
                    const SizedBox(height: 12),
                    _Stepper(
                      value: _courtCount,
                      min: 1,
                      max: 20,
                      onChanged: (v) => setState(() => _courtCount = v),
                      label: 'court(s)',
                    ),
                    const SizedBox(height: 24),

                    // ── Time slots ─────────────────────────────────────
                    Row(
                      children: [
                        const _Label('Time Slots'),
                        const Spacer(),
                        Text('${_timeSlots.length} added',
                            style: const TextStyle(
                                fontSize: 12, color: _T.textSecond)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _slotCtrl,
                            decoration: _inputDec('e.g. 08:00 – 09:00'),
                            onFieldSubmitted: (_) => _addSlot(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _addSlot,
                          style: FilledButton.styleFrom(
                              backgroundColor: _T.maroon,
                              minimumSize: const Size(48, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12))),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Quick-add common slots
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _quickSlots.map((s) {
                        final added = _timeSlots.contains(s);
                        return GestureDetector(
                          onTap: () {
                            if (!added) {
                              setState(() => _timeSlots.add(s));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: added
                                  ? _T.maroonFade
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: added
                                      ? _T.maroon.withOpacity(0.4)
                                      : Colors.transparent),
                            ),
                            child: Text(s,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: added
                                        ? _T.maroon
                                        : Colors.grey.shade600)),
                          ),
                        );
                      }).toList(),
                    ),
                    if (_timeSlots.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._timeSlots.asMap().entries.map((e) => _SlotRow(
                            slot: e.value,
                            onDelete: () => setState(
                                () => _timeSlots.removeAt(e.key)),
                          )),
                    ],
                    const SizedBox(height: 32),

                    // ── Save button ───────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _T.maroon,
                          disabledBackgroundColor:
                              _T.maroon.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white))
                            : Text(isEdit ? 'Save Changes' : 'Add Sport',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _quickSlots = [
    '08:00 – 09:00', '09:00 – 10:00', '10:00 – 11:00', '11:00 – 12:00',
    '12:00 – 13:00', '14:00 – 15:00', '15:00 – 16:00', '16:00 – 17:00',
    '17:00 – 18:00', '18:00 – 19:00', '19:00 – 20:00',
    '08:00 – 10:00', '10:00 – 12:00', '14:00 – 16:00', '16:00 – 18:00',
  ];
}

// ── Small shared widgets ──────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: _T.textPrimary));
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _T.maroonFade : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? _T.maroon : Colors.grey.shade300,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? _T.maroon : Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? _T.maroon : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String label;
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepBtn(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged(value - 1)),
        const SizedBox(width: 16),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: '$value ',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _T.maroon)),
              TextSpan(
                  text: label,
                  style: const TextStyle(
                      fontSize: 13, color: _T.textSecond)),
            ],
          ),
        ),
        const Spacer(),
        _StepBtn(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged(value + 1)),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? _T.maroonFade : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: enabled
                  ? _T.maroon.withOpacity(0.3)
                  : Colors.grey.shade200),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled ? _T.maroon : Colors.grey.shade400),
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final String slot;
  final VoidCallback onDelete;
  const _SlotRow({required this.slot, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _T.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, size: 16, color: _T.textSecond),
          const SizedBox(width: 10),
          Expanded(
              child: Text(slot,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close_rounded,
                size: 18, color: Colors.red.shade400),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _T.textSecond),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: _T.textSecond)),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No sports configured',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _T.textSecond)),
          const SizedBox(height: 6),
          const Text('Tap "Add Sport" to get started.',
              style: TextStyle(fontSize: 13, color: _T.textHint)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Sport'),
            style: FilledButton.styleFrom(backgroundColor: _T.maroon),
          ),
        ],
      ),
    );
  }
}

// ── Icon helper (fallback-safe) ───────────────────────────────────────────────
IconData _sportIcon(String name) {
  switch (name.toLowerCase()) {
    case 'badminton':    return Icons.sports_tennis;
    case 'table tennis': return Icons.sports_handball;
    case 'volleyball':  return Icons.sports_volleyball;
    case 'squash':      return Icons.sports_baseball;
    case 'basketball':  return Icons.sports_basketball;
    case 'football':
    case 'futsal':      return Icons.sports_soccer;
    case 'swimming':    return Icons.pool_rounded;
    default:            return Icons.sports_rounded;
  }
}

InputDecoration _inputDec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: _T.textHint),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _T.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _T.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _T.maroon, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );