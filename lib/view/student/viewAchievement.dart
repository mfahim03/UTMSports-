import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../model/achievement_model.dart';
import '../../viewmodel/achievement_viewmodel.dart';

class ViewAchievementsPage extends StatelessWidget {
  final bool embedded;
  const ViewAchievementsPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AchievementViewModel(),
      child: _ViewAchievementsContent(embedded: embedded),
    );
  }
}

class _ViewAchievementsContent extends StatelessWidget {
  final bool embedded;
  const _ViewAchievementsContent({required this.embedded});

  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AchievementViewModel>();

    final body = Column(
      children: [
        // Category filter chips
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: AchievementViewModel.categories.length,
            itemBuilder: (_, i) {
              final cat = AchievementViewModel.categories[i];
              final selected = vm.selectedCategory == cat;
              return GestureDetector(
                onTap: () => vm.setCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected
                        ? _maroon
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cat,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : Colors.grey.shade600)),
                ),
              );
            },
          ),
        ),

        // Achievement list
        Expanded(
          child: StreamBuilder<List<AchievementModel>>(
            stream: vm.stream,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: _maroon));
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final list = snap.data ?? [];
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No achievements yet',
                          style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: list.length,
                itemBuilder: (_, i) =>
                    _AchievementCard(item: list[i]),
              );
            },
          ),
        ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('Achievements',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: body,
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementModel item;
  const _AchievementCard({required this.item});

  static const _categoryIcons = <String, IconData>{
    'Badminton': Icons.sports_tennis,
    'Running': Icons.directions_run,
    'Volleyball': Icons.sports_volleyball,
    'Squash': Icons.sports_handball,
    'Table Tennis': Icons.sports_tennis,
  };

  Color _awardColor(String award) {
    final a = award.toLowerCase();
    if (a.contains('gold') || a.contains('champion') || a.contains('1st')) {
      return const Color(0xFFB8860B);
    }
    if (a.contains('silver') || a.contains('2nd')) {
      return const Color(0xFF607D8B);
    }
    if (a.contains('bronze') || a.contains('3rd')) {
      return const Color(0xFF8B5E3C);
    }
    return const Color(0xFF800000);
  }

  @override
  Widget build(BuildContext context) {
    final icon =
        _categoryIcons[item.category] ?? Icons.emoji_events_rounded;
    final awardColor = _awardColor(item.award);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: awardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: awardColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 3),
                Text(item.studentName,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: awardColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.emoji_events,
                              color: awardColor, size: 12),
                          const SizedBox(width: 4),
                          Text(item.award,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: awardColor,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.date,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500)),
                  ],
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(item.description!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}