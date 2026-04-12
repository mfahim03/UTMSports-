import 'package:flutter/material.dart';

class BookFacilityPage extends StatefulWidget {
  final bool embedded;
  const BookFacilityPage({super.key, this.embedded = false});

  @override
  State<BookFacilityPage> createState() => _BookFacilityPageState();
}

class _BookFacilityPageState extends State<BookFacilityPage> {
  static const _maroon = Color(0xFF800000);

  int _selectedSport = -1;
  DateTime? _selectedDate;

  final _sports = [
    {'label': 'Badminton', 'icon': Icons.sports_tennis},
    {'label': 'Table Tennis', 'icon': Icons.sports_tennis},
    {'label': 'Volleyball', 'icon': Icons.sports_volleyball},
    {'label': 'Squash', 'icon': Icons.sports_handball},
  ];

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Sport',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
            ),
            itemCount: _sports.length,
            itemBuilder: (_, i) {
              final selected = _selectedSport == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedSport = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: selected ? _maroon : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? _maroon
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _sports[i]['icon'] as IconData,
                        color: selected ? Colors.white : _maroon,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _sports[i]['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color:
                              selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text('Select Date',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate:
                    DateTime.now().add(const Duration(days: 30)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(
                        primary: _maroon),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      color: _maroon, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate == null
                        ? 'Choose a date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: _selectedDate == null
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedSport >= 0 && _selectedDate != null
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Booking confirmed for ${_sports[_selectedSport]['label']}!'),
                          backgroundColor: _maroon,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _maroon,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Confirm Booking',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('Book Facility',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: body,
    );
  }
}