import 'package:flutter/material.dart';

class ViewBookingPage extends StatelessWidget {
  final bool embedded;
  const ViewBookingPage({super.key, this.embedded = false});

  static const _maroon = Color(0xFF800000);

  static const _bookings = [
    {
      'title': 'Badminton Court Indoor - Court 8',
      'date': '17 Nov 2025',
      'time': '16:50 – 18:50',
      'status': 'To be check in',
      'statusColor': Color(0xFF800000),
      'icon': Icons.sports_tennis,
    },
    {
      'title': 'Volleyball Court Outdoor - Court 2',
      'date': '20 Nov 2025',
      'time': '08:00 – 10:00',
      'status': 'Confirmed',
      'statusColor': Color(0xFF2E7D32),
      'icon': Icons.sports_volleyball,
    },
    {
      'title': 'Squash Court - Court 1',
      'date': '5 Oct 2025',
      'time': '14:00 – 15:00',
      'status': 'Completed',
      'statusColor': Color(0xFF555555),
      'icon': Icons.sports_handball,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final body = ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _bookings.length,
      itemBuilder: (_, i) {
        final b = _bookings[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _maroon.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(b['icon'] as IconData,
                    color: _maroon, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['title'] as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    const SizedBox(height: 3),
                    Text('${b['date']}  ·  ${b['time']}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (b['statusColor'] as Color)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(b['status'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              color: b['statusColor'] as Color,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
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
        title: const Text('My Bookings',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: body,
    );
  }
}