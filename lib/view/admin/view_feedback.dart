import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../model/feedback_model.dart';
import '../../viewmodel/feedback_viewmodel.dart';

//  DESIGN TOKENS  (shared palette)
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

  // Category colours
  static Color categoryColor(String cat) => switch (cat) {
    'Events'     => const Color(0xFF185FA5),
    'Facilities' => const Color(0xFF0F6E56),
    'App'        => const Color(0xFF854F0B),
    _            => const Color(0xFF555555),
  };

  static Color categoryBg(String cat) =>
      categoryColor(cat).withOpacity(0.08);
}

//  ROOT
class ViewFeedbackPage extends StatelessWidget {
  const ViewFeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FeedbackViewModel(),
      child: const _ViewFeedbackContent(),
    );
  }
}

//  CONTENT
class _ViewFeedbackContent extends StatelessWidget {
  const _ViewFeedbackContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FeedbackViewModel>();
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
            // Maroon header 
            _buildHeader(context, vm, mq),

            // Stats row 
            _StatsRow(stream: vm.stream),

            // Feed 
            Expanded(
              child: StreamBuilder<List<FeedbackModel>>(
                stream: vm.stream,
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: _T.maroon, strokeWidth: 2.5));
                  }
                  if (snap.hasError) {
                    return _ErrorPlaceholder(message: '${snap.error}');
                  }
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return _EmptyPlaceholder(
                        category: vm.selectedCategory);
                  }
                  return ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _FeedbackCard(item: list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER 
  Widget _buildHeader(
      BuildContext context, FeedbackViewModel vm, MediaQueryData mq) {
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
          // Back + title row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
            child: Row(
              children: [
                // Back button
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
                      Text('Student Feedback',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3)),
                      Text('Review and monitor submissions',
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
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 10),
              itemCount: FeedbackViewModel.categories.length,
              itemBuilder: (_, i) {
                final cat      = FeedbackViewModel.categories[i];
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
}

//  STATS ROW  — quick at-a-glance summary
class _StatsRow extends StatelessWidget {
  final Stream<List<FeedbackModel>> stream;
  const _StatsRow({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FeedbackModel>>(
      stream: stream,
      builder: (_, snap) {
        final list  = snap.data ?? [];
        final total = list.length;
        final avg   = total == 0
            ? 0.0
            : list.map((f) => f.rating).reduce((a, b) => a + b) /
                total;

        return Container(
          color: _T.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Row(
            children: [
              _StatChip(
                icon: Icons.feedback_rounded,
                label: 'Total',
                value: '$total',
                color: _T.maroon,
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.star_rounded,
                label: 'Avg Rating',
                value: avg.toStringAsFixed(1),
                color: const Color(0xFF8B6914),
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.today_rounded,
                label: 'This month',
                value: '${_thisMonth(list)}',
                color: const Color(0xFF0F5F8A),
              ),
            ],
          ),
        );
      },
    );
  }

  int _thisMonth(List<FeedbackModel> list) {
    final now = DateTime.now();
    return list
        .where((f) =>
            f.submittedAt.month == now.month &&
            f.submittedAt.year == now.year)
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

//  FEEDBACK CARD
class _FeedbackCard extends StatefulWidget {
  final FeedbackModel item;
  const _FeedbackCard({required this.item});

  @override
  State<_FeedbackCard> createState() => _FeedbackCardState();
}

class _FeedbackCardState extends State<_FeedbackCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _ctrl;
  late final Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final f        = widget.item;
    final catColor = _T.categoryColor(f.category);

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
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + name + category 
                Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: catColor.withOpacity(0.12),
                      child: Text(
                        f.studentName.isNotEmpty
                            ? f.studentName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                            color: catColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.studentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _T.textPrimary)),
                          const SizedBox(height: 1),
                          Text(f.studentEmail,
                              style: const TextStyle(
                                  fontSize: 11.5, color: _T.textHint),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _T.categoryBg(f.category),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: catColor.withOpacity(0.28)),
                      ),
                      child: Text(f.category,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: catColor)),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Stars + date + chevron 
                Row(
                  children: [
                    // Stars
                    ...List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          i < f.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i < f.rating
                              ? const Color(0xFFFFB800)
                              : _T.divider,
                          size: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Rating number
                    Text(
                      '${f.rating}.0',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _T.textSecond),
                    ),
                    const Spacer(),
                    // Date
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded,
                            size: 12, color: _T.textHint),
                        const SizedBox(width: 3),
                        Text(
                          _formatDate(f.submittedAt),
                          style: const TextStyle(
                              fontSize: 11, color: _T.textHint),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Expand chevron
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _T.textHint,
                          size: 20),
                    ),
                  ],
                ),

                // Message (animated expand) 
                SizeTransition(
                  sizeFactor: _expandAnim,
                  axisAlignment: -1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 1,
                        color: _T.divider,
                      ),
                      const SizedBox(height: 12),
                      // "Message" label
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Student Message',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _T.textHint,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f.message,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _T.textPrimary,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }
}

//  EMPTY PLACEHOLDER
class _EmptyPlaceholder extends StatelessWidget {
  final String category;
  const _EmptyPlaceholder({required this.category});

  @override
  Widget build(BuildContext context) {
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
            child: const Icon(Icons.feedback_outlined,
                size: 36, color: _T.maroon),
          ),
          const SizedBox(height: 16),
          const Text('No feedback yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _T.textSecond)),
          const SizedBox(height: 4),
          Text(
            category == 'All'
                ? 'No submissions have been made.'
                : 'No "$category" feedback found.',
            style: const TextStyle(fontSize: 12.5, color: _T.textHint),
          ),
        ],
      ),
    );
  }
}

//  ERROR PLACEHOLDER
class _ErrorPlaceholder extends StatelessWidget {
  final String message;
  const _ErrorPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 40, color: _T.textHint),
          const SizedBox(height: 12),
          const Text('Could not load feedback',
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