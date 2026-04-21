import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/achievement_model.dart';
import '../../viewmodel/achievement_viewmodel.dart';

//  DESIGN TOKENS
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

  // Award tier colours
  static Color awardColor(String award) {
    final a = award.toLowerCase();
    if (a.contains('gold') || a.contains('1st') || a.contains('first'))
      return const Color(0xFFB8860B);
    if (a.contains('silver') || a.contains('2nd') || a.contains('second'))
      return const Color(0xFF607D8B);
    if (a.contains('bronze') || a.contains('3rd') || a.contains('third'))
      return const Color(0xFF8D4E2A);
    return const Color(0xFF555555);
  }

  static Color awardBg(String award) => awardColor(award).withOpacity(0.09);
}

//  ROOT
class ManageAchievementsPage extends StatelessWidget {
  const ManageAchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AchievementViewModel(),
      child: const _ManageAchievementsContent(),
    );
  }
}

//  CONTENT
class _ManageAchievementsContent extends StatelessWidget {
  const _ManageAchievementsContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AchievementViewModel>();
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
            // Gradient header 
            _buildHeader(context, vm, mq),

            // Summary strip 
            _SummaryStrip(stream: vm.stream),

            // Achievement list 
            Expanded(
              child: StreamBuilder<List<AchievementModel>>(
                stream: vm.stream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _T.maroon, strokeWidth: 2.5));
                  }
                  if (snap.hasError) {
                    return _ErrorState(message: '${snap.error}');
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return _EmptyState(
                      onAdd: () => _showForm(context, vm, null),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _AchievementCard(
                      item: list[i],
                      onEdit: () => _showForm(context, vm, list[i]),
                      onDelete: () =>
                          _confirmDelete(context, vm, list[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // FAB 
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _T.maroon,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text('Add Achievement',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          onPressed: () => _showForm(context, vm, null),
        ),
      ),
    );
  }

  // HEADER 
  Widget _buildHeader(
      BuildContext context, AchievementViewModel vm, MediaQueryData mq) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_T.maroonDark, _T.maroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(0, mq.padding.top, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Manage Achievements',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3)),
                      Text('Track and celebrate student excellence',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white60,
                              letterSpacing: 0.1)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Category filter chips 
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              itemCount: AchievementViewModel.categories.length,
              itemBuilder: (_, i) {
                final cat      = AchievementViewModel.categories[i];
                final selected = vm.selectedCategory == cat;
                return GestureDetector(
                  onTap: () => vm.setCategory(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? _T.maroon : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // SHOW FORM 
  void _showForm(
      BuildContext context, AchievementViewModel vm, AchievementModel? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _AchievementForm(existing: existing),
      ),
    );
  }

  // DELETE CONFIRM 
  void _confirmDelete(
      BuildContext context, AchievementViewModel vm, AchievementModel item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Delete Achievement',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: _T.textPrimary)),
            ),
          ],
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
                fontSize: 13.5, color: _T.textSecond, height: 1.5),
            children: [
              const TextSpan(text: 'Remove '),
              TextSpan(
                text: '"${item.title}"',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: _T.textPrimary),
              ),
              const TextSpan(text: ' permanently? This cannot be undone.'),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: _T.textSecond,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await vm.delete(item.id);
              if (context.mounted && vm.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(vm.error!),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

//  SUMMARY STRIP  — live stats from stream
class _SummaryStrip extends StatelessWidget {
  final Stream<List<AchievementModel>> stream;
  const _SummaryStrip({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AchievementModel>>(
      stream: stream,
      builder: (_, snap) {
        final list     = snap.data ?? [];
        final total    = list.length;
        final students = list.map((a) => a.studentName).toSet().length;
        final recent   = _recentCount(list);

        return Container(
          color: _T.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              _StatChip(
                icon: Icons.emoji_events_rounded,
                label: 'Total',
                value: '$total',
                color: _T.maroon,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.people_alt_rounded,
                label: 'Students',
                value: '$students',
                color: const Color(0xFF0A7A5A),
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.calendar_month_rounded,
                label: 'This month',
                value: '$recent',
                color: const Color(0xFF0F5F8A),
              ),
            ],
          ),
        );
      },
    );
  }

  int _recentCount(List<AchievementModel> list) {
    final now = DateTime.now();
    return list
        .where((a) =>
            a.createdAt.month == now.month &&
            a.createdAt.year == now.year)
        .length;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: color,
                          height: 1)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: _T.textHint,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  ACHIEVEMENT CARD
class _AchievementCard extends StatelessWidget {
  final AchievementModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AchievementCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final awardColor = _T.awardColor(item.award);
    final awardBg    = _T.awardBg(item.award);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _T.divider),
        boxShadow: _T.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetail(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trophy icon 
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: _T.maroonFade,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: _T.maroon, size: 28),
                ),
                const SizedBox(width: 14),

                // Details 
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _T.textPrimary)),
                      const SizedBox(height: 3),
                      // Student name with icon
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 12, color: _T.textHint),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(item.studentName,
                                style: const TextStyle(
                                    fontSize: 12, color: _T.textSecond),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Pills row
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Pill(
                            label: item.category,
                            bg: _T.maroonFade,
                            fg: _T.maroon,
                          ),
                          _Pill(
                            label: item.award,
                            bg: awardBg,
                            fg: awardColor,
                          ),
                          _Pill(
                            label: item.date,
                            bg: const Color(0xFFF0F4F8),
                            fg: _T.textSecond,
                            icon: Icons.calendar_today_rounded,
                          ),
                        ],
                      ),
                      // Description preview (if exists)
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.description!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: _T.textHint,
                              height: 1.4),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Action buttons 
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      icon: Icons.edit_outlined,
                      color: const Color(0xFF0F5F8A),
                      bg: const Color(0xFFECF5FF),
                      onTap: onEdit,
                      tooltip: 'Edit',
                    ),
                    const SizedBox(height: 6),
                    _IconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red.shade500,
                      bg: Colors.red.withOpacity(0.07),
                      onTap: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    // Future: expand to full detail sheet
  }
}

//  PILL LABEL
class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: fg),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: fg)),
        ],
      ),
    );
  }
}

//  ICON BUTTON  (card actions)
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

//  ADD / EDIT FORM  (bottom sheet)
class _AchievementForm extends StatefulWidget {
  final AchievementModel? existing;
  const _AchievementForm({this.existing});

  @override
  State<_AchievementForm> createState() => _AchievementFormState();
}

class _AchievementFormState extends State<_AchievementForm> {
  final _formKey    = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _awardCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _descCtrl;
  late String _category;

  @override
  void initState() {
    super.initState();
    final e   = widget.existing;
    _nameCtrl  = TextEditingController(text: e?.studentName ?? '');
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _awardCtrl = TextEditingController(text: e?.award ?? '');
    _dateCtrl  = TextEditingController(text: e?.date ?? '');
    _descCtrl  = TextEditingController(text: e?.description ?? '');
    _category  = e?.category ??
        AchievementViewModel.categories[1]; // default to first sport
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _awardCtrl.dispose();
    _dateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AchievementViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final model = widget.existing != null
        ? widget.existing!.copyWith(
            studentName: _nameCtrl.text.trim(),
            title: _titleCtrl.text.trim(),
            category: _category,
            award: _awardCtrl.text.trim(),
            date: _dateCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          )
        : AchievementModel(
            id: '',
            studentName: _nameCtrl.text.trim(),
            title: _titleCtrl.text.trim(),
            category: _category,
            award: _awardCtrl.text.trim(),
            date: _dateCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            createdAt: DateTime.now(),
          );

    final ok = widget.existing != null
        ? await vm.update(model)
        : await vm.add(model);

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(widget.existing != null
                  ? 'Achievement updated successfully'
                  : 'Achievement added successfully'),
            ],
          ),
          backgroundColor: _T.maroon,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.error ?? 'An error occurred'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _T.maroon),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      _dateCtrl.text =
          '${picked.day} ${months[picked.month]} ${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm     = context.watch<AchievementViewModel>();
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle 
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _T.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet title 
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _T.maroonFade,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events_rounded,
                        color: _T.maroon, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Achievement' : 'Add Achievement',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _T.textPrimary),
                      ),
                      Text(
                        isEdit
                            ? 'Update the details below'
                            : 'Fill in the details below',
                        style: const TextStyle(
                            fontSize: 12, color: _T.textHint),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section: Student Info 
              _sectionLabel('Student Information'),
              const SizedBox(height: 10),
              _FormField(
                ctrl: _nameCtrl,
                label: 'Student Name',
                icon: Icons.person_outline_rounded,
                required: true,
              ),
              const SizedBox(height: 14),

              // Section: Achievement Info 
              _sectionLabel('Achievement Details'),
              const SizedBox(height: 10),
              _FormField(
                ctrl: _titleCtrl,
                label: 'Achievement Title',
                icon: Icons.emoji_events_outlined,
                required: true,
              ),
              const SizedBox(height: 14),

              // Category dropdown
              _CategoryDropdown(
                value: _category,
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),

              _FormField(
                ctrl: _awardCtrl,
                label: 'Award / Result (e.g. Gold, 1st Place)',
                icon: Icons.military_tech_outlined,
                required: true,
              ),
              const SizedBox(height: 14),

              // Date field with picker
              _FormField(
                ctrl: _dateCtrl,
                label: 'Date',
                icon: Icons.calendar_today_outlined,
                required: true,
                readOnly: true,
                onTap: _pickDate,
                suffixIcon: const Icon(Icons.arrow_drop_down_rounded,
                    color: _T.textHint),
              ),
              const SizedBox(height: 14),

              _FormField(
                ctrl: _descCtrl,
                label: 'Description (optional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 28),

              // Submit button 
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: vm.busy ? null : () => _submit(vm),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.maroon,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _T.maroon.withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: vm.busy
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEdit
                                  ? Icons.save_rounded
                                  : Icons.add_circle_outline_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit ? 'Save Changes' : 'Add Achievement',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Row(
        children: [
          Container(
            width: 3, height: 13,
            decoration: BoxDecoration(
              color: _T.maroon,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _T.textHint,
                  letterSpacing: 0.5)),
        ],
      );
}

//  FORM FIELD WIDGET
class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool required;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const _FormField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null
          : null,
      style: const TextStyle(fontSize: 13.5, color: _T.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _T.textHint),
        prefixIcon: Icon(icon, size: 20, color: _T.textHint),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _T.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _T.maroon, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.8)),
      ),
    );
  }
}

//  CATEGORY DROPDOWN
class _CategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13.5, color: _T.textPrimary),
      dropdownColor: _T.surface,
      icon: const Icon(Icons.arrow_drop_down_rounded, color: _T.textHint),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: const TextStyle(fontSize: 13, color: _T.textHint),
        prefixIcon: const Icon(Icons.category_outlined,
            size: 20, color: _T.textHint),
        filled: true,
        fillColor: _T.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _T.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: _T.maroon, width: 1.8)),
      ),
      items: AchievementViewModel.categories
          .skip(1) // skip 'All'
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c,
                    style: const TextStyle(
                        fontSize: 13.5, color: _T.textPrimary)),
              ))
          .toList(),
    );
  }
}

//  EMPTY STATE
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _T.maroonFade,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.emoji_events_outlined,
                size: 42, color: _T.maroon),
          ),
          const SizedBox(height: 18),
          const Text('No achievements yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _T.textSecond)),
          const SizedBox(height: 6),
          const Text('Start by adding the first achievement.',
              style: TextStyle(fontSize: 13, color: _T.textHint)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: _T.maroon,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Achievement',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

//  ERROR STATE
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 40, color: _T.textHint),
          const SizedBox(height: 12),
          const Text('Could not load achievements',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: _T.textSecond)),
          const SizedBox(height: 4),
          Text(message,
              style: const TextStyle(
                  fontSize: 11.5, color: _T.textHint)),
        ],
      ),
    );
  }
}