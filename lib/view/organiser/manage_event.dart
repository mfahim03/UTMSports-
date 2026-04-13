import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/event_model.dart';
import '../../viewmodel/event_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const maroon      = Color(0xFF800000);
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

// ─────────────────────────────────────────────────────────────────────────────
//  ROOT
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
//  CONTENT
// ─────────────────────────────────────────────────────────────────────────────
class _ManageEventsContent extends StatelessWidget {
  const _ManageEventsContent();

  static const _categoryIcons = <String, IconData>{
    'Running':      Icons.directions_run,
    'Badminton':    Icons.sports_tennis,
    'Volleyball':   Icons.sports_volleyball,
    'Squash':       Icons.sports_handball,
    'Table Tennis': Icons.sports_tennis,
    'Other':        Icons.emoji_events,
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
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
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
            const Expanded(
              child: Text('Delete Event',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _T.textPrimary)),
            ),
          ],
        ),
        content: Text('Remove "${item.title}" from the system?',
            style: const TextStyle(
                fontSize: 13.5, color: _T.textSecond, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: _T.textSecond),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.delete(item.id);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
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
            tooltip: 'Add event',
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
          if (snap.hasError) {
            return Center(
                child: Text('Error: ${snap.error}',
                    style:
                        const TextStyle(color: _T.textSecond)));
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
                          color: _T.textSecond)),
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
              final icon = _categoryIcons[e.category] ??
                  Icons.emoji_events;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: _T.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _T.divider),
                  boxShadow: _T.shadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _T.maroonFade,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon,
                            color: _T.maroon, size: 26),
                      ),
                      const SizedBox(width: 14),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(e.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: _T.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Text(
                              '${e.date}  ·  ${e.location}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _T.textSecond),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _Pill(
                                    label: e.category,
                                    color: _T.maroon),
                                const SizedBox(width: 6),
                                _Pill(
                                    label: e.spots,
                                    color: const Color(0xFF0A7A5A)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _showForm(context, vm, e),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF3FF),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Color(0xFF185FA5)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () =>
                                _confirmDelete(context, vm, e),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.07),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Colors.red.shade400),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
//  EVENT FORM  (add / edit bottom sheet)
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
  late final TextEditingController _spotsCtrl;
  late final TextEditingController _descCtrl;
  late String _category;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleCtrl    = TextEditingController(text: e?.title ?? '');
    _dateCtrl     = TextEditingController(text: e?.date ?? '');
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _spotsCtrl    = TextEditingController(text: e?.spots ?? '');
    _descCtrl     = TextEditingController(text: e?.description ?? '');
    _category = e?.category ?? EventViewModel.categories.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _locationCtrl.dispose();
    _spotsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(EventViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final model = widget.existing != null
        ? widget.existing!.copyWith(
            title: _titleCtrl.text.trim(),
            date: _dateCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            category: _category,
            spots: _spotsCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          )
        : EventModel(
            id: '',
            title: _titleCtrl.text.trim(),
            date: _dateCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            category: _category,
            spots: _spotsCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            createdBy: uid,
            createdAt: DateTime.now(),
          );

    final ok = widget.existing != null
        ? await vm.update(model)
        : await vm.add(model);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.existing != null
            ? 'Event updated'
            : 'Event created'),
        backgroundColor: _T.maroon,
        behavior: SnackBarBehavior.floating,
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
              // Handle
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
                      color: _T.textPrimary)),
              const SizedBox(height: 20),

              _field(_titleCtrl, 'Event Title',
                  Icons.title_rounded, required: true),
              const SizedBox(height: 14),
              _field(_dateCtrl, 'Date (e.g. 10 Jan 2025)',
                  Icons.calendar_today_outlined,
                  required: true),
              const SizedBox(height: 14),
              _field(_locationCtrl, 'Location',
                  Icons.location_on_outlined,
                  required: true),
              const SizedBox(height: 14),

              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: _decor(
                    'Category', Icons.category_outlined),
                items: EventViewModel.categories
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              _field(_spotsCtrl, 'Spots (e.g. 200 spots left)',
                  Icons.people_alt_outlined,
                  required: true),
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

  Widget _field(TextEditingController ctrl, String label,
      IconData icon,
      {bool required = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
      decoration: _decor(label, icon),
    );
  }

  InputDecoration _decor(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: _T.maroon, width: 1.8)),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  PILL
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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