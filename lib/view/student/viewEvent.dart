import 'package:flutter/material.dart';

class ViewEventsPage extends StatelessWidget {
  final bool embedded;
  const ViewEventsPage({super.key, this.embedded = false});

  static const _maroon = Color(0xFF800000);

  static const _events = [
    {
      'title': 'UTMCC Run 2025',
      'date': '10 Jan 2025',
      'location': 'UTM Main Campus',
      'category': 'Running',
      'icon': Icons.directions_run,
      'spots': '200 spots left',
    },
    {
      'title': 'Badminton Inter-Faculty',
      'date': '20 Jan 2025',
      'location': 'Indoor Sports Hall',
      'category': 'Badminton',
      'icon': Icons.sports_tennis,
      'spots': '32 spots left',
    },
    {
      'title': 'Volleyball Championship',
      'date': '5 Feb 2025',
      'location': 'Outdoor Court B',
      'category': 'Volleyball',
      'icon': Icons.sports_volleyball,
      'spots': '12 spots left',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final body = ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _events.length,
      itemBuilder: (_, i) {
        final e = _events[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _maroon.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(e['icon'] as IconData,
                      color: _maroon, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e['title'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('${e['date']}  ·  ${e['location']}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _maroon.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(e['category'] as String,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _maroon,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Text(e['spots'] as String,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('Sports Events',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: body,
    );
  }
}