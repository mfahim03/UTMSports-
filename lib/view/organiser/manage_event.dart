import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/event_model.dart';
import '../../viewmodel/event_viewmodel.dart';
import 'manage_registrations_page.dart';

class _T {
  static const maroon     = Color(0xFF800000);
  static const maroonFade = Color(0xFFF9F0F0);
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

class ManageEventsPage extends StatelessWidget {
  const ManageEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EventViewModel(),
      child: const _ManageEventsContent(),
    );
  }
}

class _ManageEventsContent extends StatelessWidget {
  const _ManageEventsContent();

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

  void _showForm(BuildContext context, EventViewModel vm,
      EventModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _EventForm(existing: existing),
      ),
    );
  }

  void _confirmDelete(BuildContext context, EventViewModel vm,
      EventModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Delete Event',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _T.textPri)),
        ]),
        content: Text('Remove "${item.title}"?',
            style: const TextStyle(
                fontSize: 13.5, color: _T.textSec, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.delete(item.id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm  = context.watch<EventViewModel>();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.maroon,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Events',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 26),
            onPressed: () => _showForm(context, vm, null),
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: vm.organiserStream(uid),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: _T.maroon, strokeWidth: 2.5));
          }
          final list = snap.data ?? [];

          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _T.maroonFade,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.event_outlined,
                        size: 36, color: _T.maroon),
                  ),
                  const SizedBox(height: 16),
                  const Text('No events yet',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _T.textSec)),
                  const SizedBox(height: 4),
                  const Text('Tap + to create your first event.',
                      style: TextStyle(
                          fontSize: 12.5, color: _T.textHint)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => _showForm(context, vm, null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _T.maroon,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Create Event',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final e    = list[i];
              final col  = _colors[e.category] ?? _T.maroon;
              final icon = _icons[e.category] ?? Icons.emoji_events;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: col.withOpacity(0.2)),
                  boxShadow: _T.shadow,
                ),
                child: Column(
                  children: [
                    // Card header
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(e.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: _T.textPri),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text('${e.date}  ·  ${e.location}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: _T.textSec)),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    _Pill(
                                        label: e.category,
                                        color: col),
                                    _Pill(
                                      label: e.maxPlayers != null
                                          ? '${e.minPlayers}–${e.maxPlayers} pax'
                                          : '${e.minPlayers}+ pax',
                                      color:
                                          const Color(0xFF0A7A5A),
                                    ),
                                    if (e.maxTeams != null)
                                      _Pill(
                                        label:
                                            '${e.maxTeams} teams max',
                                        color: Colors.purple.shade700,
                                      ),
                                    _Pill(
                                      label: e.registrationOpen
                                          ? 'Open'
                                          : 'Closed',
                                      color: e.registrationOpen
                                          ? Colors.green.shade700
                                          : Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _IconBtn(
                                icon: Icons.edit_outlined,
                                color: const Color(0xFF185FA5),
                                bg: const Color(0xFFEBF3FF),
                                onTap: () =>
                                    _showForm(context, vm, e),
                              ),
                              const SizedBox(height: 6),
                              _IconBtn(
                                icon: Icons.delete_outline_rounded,
                                color: Colors.red.shade400,
                                bg: Colors.red.withOpacity(0.07),
                                onTap: () =>
                                    _confirmDelete(context, vm, e),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // View registrations button
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ManageRegistrationsPage(event: e),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: col.withOpacity(0.05),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(18)),
                          border: Border(
                              top: BorderSide(
                                  color: col.withOpacity(0.12))),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 11),
                        child: Row(
                          children: [
                            Icon(Icons.how_to_reg_outlined,
                                color: col, size: 15),
                            const SizedBox(width: 8),
                            Text('View Registrations',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: col)),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded,
                                color: col, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _T.maroon,
        foregroundColor: Colors.white,
        onPressed: () => _showForm(context, vm, null),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  EVENT FORM
// ─────────────────────────────────────────────────────────────────────────────
class _EventForm extends StatefulWidget {
  final EventModel? existing;
  const _EventForm({this.existing});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _maxTeamsCtrl;

  late String _category;
  late bool _regOpen;
  late List<String> _badmintonTypes;
  bool _maxUnlimited    = false;
  bool _maxTeamsUnlimited = true;
  DateTime? _selectedDate;

  static const _categories = [
    'Futsal', 'Volleyball', 'Badminton', 'PUBG',
    'Mobile Legends', 'Running', 'Squash', 'Table Tennis', 'Other'
  ];
  static const _badmintonOptions = ['Solo', 'Double', 'Mixed'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl    = TextEditingController(text: e?.title ?? '');
    _dateCtrl     = TextEditingController(text: e?.date ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _descCtrl     = TextEditingController(text: e?.description ?? '');
    _category     = e?.category ?? 'Futsal';
    _regOpen      = e?.registrationOpen ?? true;
    _badmintonTypes = List.from(e?.badmintonTypes ?? []);
    _maxUnlimited   = e?.maxPlayers == null;
    _maxTeamsUnlimited = e?.maxTeams == null;

    if (e != null && e.dateStr.isNotEmpty) {
      try {
        final p = e.dateStr.split('-');
        _selectedDate = DateTime(
            int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      } catch (_) {}
    }

    final defaults = EventModel.defaultsFor(_category);
    _minCtrl = TextEditingController(
        text: '${e?.minPlayers ?? defaults['min']}');
    _maxCtrl = TextEditingController(
        text: e?.maxPlayers != null
            ? '${e!.maxPlayers}'
            : '${defaults['max'] ?? ''}');
    _maxTeamsCtrl = TextEditingController(
        text: e?.maxTeams != null ? '${e!.maxTeams}' : '');

    if (e?.maxPlayers == null && defaults['max'] == null) {
      _maxUnlimited = true;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _maxTeamsCtrl.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String cat) {
    final d = EventModel.defaultsFor(cat);
    setState(() {
      _category = cat;
      _minCtrl.text = '${d['min']}';
      final max = d['max'];
      if (max == null) {
        _maxUnlimited = true;
        _maxCtrl.text = '';
      } else {
        _maxUnlimited = false;
        _maxCtrl.text = '$max';
      }
      _badmintonTypes = List<String>.from(d['badminton'] as List);
    });
  }

  Future<void> _submit(EventViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select an event date'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final minP  = int.tryParse(_minCtrl.text.trim()) ?? 1;
    final maxP  = _maxUnlimited ? null : int.tryParse(_maxCtrl.text.trim());
    final maxT  = _maxTeamsUnlimited
        ? null
        : int.tryParse(_maxTeamsCtrl.text.trim());

    final d = _selectedDate!;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final displayDate = '${d.day} ${months[d.month]} ${d.year}';
    final dateStr =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final model = widget.existing != null
        ? widget.existing!.copyWith(
            title: _titleCtrl.text.trim(),
            date: displayDate,
            dateStr: dateStr,
            location: _locationCtrl.text.trim(),
            category: _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            minPlayers: minP,
            maxPlayers: maxP,
            clearMax: _maxUnlimited,
            maxTeams: maxT,
            clearMaxTeams: _maxTeamsUnlimited,
            badmintonTypes: _badmintonTypes,
            registrationOpen: _regOpen,
          )
        : EventModel(
            id: '',
            title: _titleCtrl.text.trim(),
            date: displayDate,
            dateStr: dateStr,
            location: _locationCtrl.text.trim(),
            category: _category,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            createdBy: uid,
            createdAt: DateTime.now(),
            minPlayers: minP,
            maxPlayers: maxP,
            maxTeams: maxT,
            badmintonTypes: _badmintonTypes,
            registrationOpen: _regOpen,
          );

    final ok = widget.existing != null
        ? await vm.update(model)
        : await vm.add(model);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            widget.existing != null ? 'Event updated' : 'Event created'),
        backgroundColor: _T.maroon,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error ?? 'Error occurred'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<EventViewModel>();
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text(isEdit ? 'Edit Event' : 'Create Event',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _T.textPri)),
              const SizedBox(height: 20),

              // ── Category picker ───────────────────────────────────
              const _Label('Sport / Category'),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    final sel = _category == cat;
                    return GestureDetector(
                      onTap: () => _onCategoryChanged(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? _T.maroon
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? _T.maroon
                                  : Colors.grey.shade300),
                        ),
                        child: Text(cat,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? Colors.white
                                    : _T.textSec)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              _field(_titleCtrl, 'Event Title', Icons.title_rounded,
                  required: true),
              const SizedBox(height: 12),

              // ── Date picker ───────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  final now     = DateTime.now();
                  final minDate = DateTime(now.year, now.month, now.day + 1);
                  final picked  = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? minDate,
                    firstDate: minDate,
                    lastDate: DateTime(now.year + 2),
                    helpText: 'Select event date',
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: _T.maroon),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                      const m = [
                        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      _dateCtrl.text =
                          '${picked.day} ${m[picked.month]} ${picked.year}';
                    });
                  }
                },
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: _dateCtrl,
                    validator: (_) => _selectedDate == null
                        ? 'Please select a date'
                        : null,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Event Date',
                      prefixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 20),
                      suffixIcon: _selectedDate != null
                          ? null
                          : const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20),
                      hintText: 'Tap to pick date',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: _T.maroon, width: 1.8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _field(_locationCtrl, 'Location',
                  Icons.location_on_outlined,
                  required: true),
              const SizedBox(height: 16),

              // ── Player config ─────────────────────────────────────
              const _Label('Player Size Per Team'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(_minCtrl, 'Min players',
                        Icons.person_outline_rounded,
                        keyboard: TextInputType.number,
                        required: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _maxUnlimited
                        ? GestureDetector(
                            onTap: () => setState(
                                () => _maxUnlimited = false),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: const Center(
                                child: Text('No max limit',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: _T.textSec)),
                              ),
                            ),
                          )
                        : _field(_maxCtrl, 'Max players (opt.)',
                            Icons.group_outlined,
                            keyboard: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    setState(() => _maxUnlimited = !_maxUnlimited),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _maxUnlimited,
                        activeColor: _T.maroon,
                        onChanged: (v) => setState(
                            () => _maxUnlimited = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('No maximum player limit',
                        style: TextStyle(
                            fontSize: 13, color: _T.textSec)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Max teams ─────────────────────────────────────────
              const _Label('Max Teams Allowed'),
              const SizedBox(height: 10),
              _maxTeamsUnlimited
                  ? GestureDetector(
                      onTap: () =>
                          setState(() => _maxTeamsUnlimited = false),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.grey.shade300),
                        ),
                        child: const Center(
                          child: Text('Unlimited teams',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _T.textSec)),
                        ),
                      ),
                    )
                  : _field(_maxTeamsCtrl, 'Max teams (opt.)',
                      Icons.group_work_outlined,
                      keyboard: TextInputType.number),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(
                    () => _maxTeamsUnlimited = !_maxTeamsUnlimited),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _maxTeamsUnlimited,
                        activeColor: _T.maroon,
                        onChanged: (v) => setState(
                            () => _maxTeamsUnlimited = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('No team limit',
                        style: TextStyle(
                            fontSize: 13, color: _T.textSec)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Badminton formats ─────────────────────────────────
              if (_category == 'Badminton') ...[
                const _Label('Available Formats'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _badmintonOptions.map((opt) {
                    final sel = _badmintonTypes.contains(opt);
                    return GestureDetector(
                      onTap: () => setState(() {
                        sel
                            ? _badmintonTypes.remove(opt)
                            : _badmintonTypes.add(opt);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? _T.maroon
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: sel
                                  ? _T.maroon
                                  : Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sel)
                              const Icon(Icons.check_rounded,
                                  size: 13, color: Colors.white),
                            if (sel) const SizedBox(width: 4),
                            Text(opt,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: sel
                                        ? Colors.white
                                        : _T.textSec)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // ── Registration open toggle ──────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _T.bg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _T.divider),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.how_to_reg_outlined,
                        size: 18, color: _T.textSec),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registration Open',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: _T.textPri)),
                          Text('Allow students to register',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _T.textSec)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _regOpen,
                      activeColor: _T.maroon,
                      onChanged: (v) =>
                          setState(() => _regOpen = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _field(_descCtrl, 'Description (optional)',
                  Icons.notes_rounded,
                  maxLines: 3),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: vm.busy ? null : () => _submit(vm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.maroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: vm.busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white))
                      : Text(
                          isEdit ? 'Save Changes' : 'Create Event',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: _T.maroon, width: 1.8)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _T.textHint,
          letterSpacing: 0.5));
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
      );
}