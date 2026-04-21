import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../viewmodel/booking_viewmodel.dart';

class BookFacilityPage extends StatelessWidget {
  final bool embedded;
  const BookFacilityPage({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookingViewModel(),
      child: _BookFacilityContent(embedded: embedded),
    );
  }
}

class _BookFacilityContent extends StatelessWidget {
  final bool embedded;
  const _BookFacilityContent({required this.embedded});

  static const _maroon     = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    final mq   = MediaQuery.of(context);
    final body = const _BookFacilityBody();

    if (embedded) {
      return Column(
        children: [
          _EmbeddedHeader(
            title: 'Daily Facility Booking',
            topPadding: mq.padding.top,
          ),
          const Expanded(child: _BookFacilityBody()),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: _maroon,
        foregroundColor: Colors.white,
        title: const Text('Daily Facility Booking',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: body,
    );
  }
}

// EMBEDDED HEADER — identical to ViewBookingPage
class _EmbeddedHeader extends StatelessWidget {
  final String title;
  final double topPadding;
  const _EmbeddedHeader({required this.title, required this.topPadding});

  static const _maroon     = Color(0xFF800000);
  static const _maroonDark = Color(0xFF5C0000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_maroonDark, _maroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 18),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _BookFacilityBody extends StatelessWidget {
  const _BookFacilityBody();
  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BookingViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(label: 'Sport'),
          const SizedBox(height: 10),
          _SportSelector(vm: vm),
          const SizedBox(height: 24),

          _SportBanner(sport: vm.selectedSport),
          const SizedBox(height: 24),

          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(label: 'Date'),
                const SizedBox(height: 16),
                _Calendar(vm: vm),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel(label: 'Time Slot'),
                const SizedBox(height: 14),
                _TimeSlots(vm: vm),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _SectionLabel(label: 'Select Court'),
                    const Spacer(),
                    if (vm.selectedSlot != null) ...[
                      _Legend(color: _maroon, label: 'Available'),
                      const SizedBox(width: 12),
                      _Legend(
                          color: Colors.grey.shade400,
                          label: 'Booked'),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                _CourtGrid(vm: vm),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _BookButton(vm: vm),
        ],
      ),
    );
  }
}

class _SportSelector extends StatelessWidget {
  final BookingViewModel vm;
  const _SportSelector({required this.vm});

  static const _icons = <String, IconData>{
    'Badminton': Icons.sports_tennis,
    'Table Tennis': Icons.sports_handball,
    'Volleyball': Icons.sports_volleyball,
    'Squash': Icons.sports_baseball,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vm.sports.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final sport = vm.sports[i];
          final selected = vm.selectedSport == sport;
          return GestureDetector(
            onTap: () => vm.setSport(sport),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 88,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF800000) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? const Color(0xFF800000) : Colors.grey.shade200,
                  width: selected ? 0 : 1,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: const Color(0xFF800000).withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icons[sport] ?? Icons.sports,
                      color: selected ? Colors.white : const Color(0xFF800000), size: 26),
                  const SizedBox(height: 6),
                  Text(sport,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black87)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SportBanner extends StatelessWidget {
  final String sport;
  const _SportBanner({required this.sport});

  static const _gradients = <String, List<Color>>{
    'Badminton': [Color(0xFF800000), Color(0xFFB91C1C)],
    'Table Tennis': [Color(0xFF7C3AED), Color(0xFFA855F7)],
    'Volleyball': [Color(0xFF0369A1), Color(0xFF0EA5E9)],
    'Squash': [Color(0xFF065F46), Color(0xFF10B981)],
  };

  static const _icons = <String, IconData>{
    'Badminton': Icons.sports_tennis,
    'Table Tennis': Icons.sports_tennis,
    'Volleyball': Icons.sports_volleyball,
    'Squash': Icons.sports_handball,
  };

  @override
  Widget build(BuildContext context) {
    final colors = _gradients[sport] ?? [const Color(0xFF800000), const Color(0xFFB91C1C)];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.centerLeft),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(_icons[sport] ?? Icons.sports, color: Colors.white.withOpacity(0.3), size: 44),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sport, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                Text('Court Reservation', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  final BookingViewModel vm;
  const _Calendar({required this.vm});

  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    final selected = vm.selectedDate;
    final first = DateTime(selected.year, selected.month, 1);
    final offset = first.weekday - 1;
    final days = DateTime(selected.year, selected.month + 1, 0).day;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${vm.getMonthName(selected.month)} ${selected.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Row(
              children: [
                _NavBtn(icon: Icons.chevron_left, onTap: () => vm.setDate(DateTime(selected.year, selected.month - 1, 1))),
                const SizedBox(width: 4),
                _NavBtn(icon: Icons.chevron_right, onTap: () => vm.setDate(DateTime(selected.year, selected.month + 1, 1))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
              .map((d) => Expanded(
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1),
          itemCount: offset + days,
          itemBuilder: (_, i) {
            if (i < offset) return const SizedBox();
            final day = i - offset + 1;
            final date = DateTime(selected.year, selected.month, day);
            final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
            final isSelected = vm.isSameDay(date, selected);
            final isToday = vm.isSameDay(date, today);

            return GestureDetector(
              onTap: isPast ? null : () => vm.setDate(date),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? _maroon : isToday ? _maroon.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isToday && !isSelected ? Border.all(color: _maroon.withOpacity(0.4), width: 1) : null,
                ),
                child: Center(
                  child: Text('$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected ? Colors.white : isPast ? Colors.grey.shade300 : Colors.black87,
                      )),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: const Color(0xFF800000)),
      ),
    );
  }
}

class _TimeSlots extends StatelessWidget {
  final BookingViewModel vm;
  const _TimeSlots({required this.vm});

  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: vm.slots.map((slot) {
        final selected = vm.selectedSlot == slot;
        return GestureDetector(
          onTap: () => vm.setSlot(slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _maroon : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? _maroon : Colors.grey.shade200, width: selected ? 0 : 1),
              boxShadow: selected ? [BoxShadow(color: _maroon.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))] : [],
            ),
            child: Text(slot, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.black87)),
          ),
        );
      }).toList(),
    );
  }
}

class _CourtGrid extends StatelessWidget {
  final BookingViewModel vm;
  const _CourtGrid({required this.vm});

  static const _maroon = Color(0xFF800000);

  @override
  Widget build(BuildContext context) {
    if (vm.selectedSlot == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, color: Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Text('Select a time slot first', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      );
    }

    if (vm.loadingCourts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: _maroon, strokeWidth: 2)),
      );
    }

    return GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.9),
      itemCount: vm.courtCount,
      itemBuilder: (_, i) {
        final court = i + 1;
        final isBooked = vm.bookedCourts.contains(court);
        final isSelected = vm.selectedCourt == court;

        return GestureDetector(
          onTap: isBooked ? null : () => vm.setCourt(court),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? _maroon : isBooked ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isSelected ? _maroon : isBooked ? Colors.grey.shade200 : _maroon.withOpacity(0.25),
                  width: isSelected ? 0 : 1),
              boxShadow: isSelected ? [BoxShadow(color: _maroon.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isBooked ? Icons.lock_rounded : Icons.sports_tennis, size: 20,
                    color: isSelected ? Colors.white : isBooked ? Colors.grey.shade400 : _maroon),
                const SizedBox(height: 5),
                Text('Court $court',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : isBooked ? Colors.grey.shade400 : Colors.black87)),
                const SizedBox(height: 2),
                Text(isBooked ? 'Booked' : 'Free',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white.withOpacity(0.8) : isBooked ? Colors.grey.shade400 : Colors.green.shade600)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookButton extends StatelessWidget {
  final BookingViewModel vm;
  const _BookButton({required this.vm});

  static const _maroon = Color(0xFF800000);

  bool get _canBook => vm.selectedSlot != null && vm.selectedCourt != null && !vm.busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 54,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: _canBook
              ? const LinearGradient(colors: [Color(0xFF800000), Color(0xFFB91C1C)], begin: Alignment.centerLeft, end: Alignment.centerRight)
              : null,
          color: _canBook ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _canBook ? [BoxShadow(color: _maroon.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))] : [],
        ),
        child: ElevatedButton(
          onPressed: _canBook ? () => _submit(context) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: vm.busy
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: _canBook ? Colors.white : Colors.grey.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text('Confirm Booking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _canBook ? Colors.white : Colors.grey.shade400)),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ok = await vm.submit(userId: user.uid, userEmail: user.email ?? '');
    if (!context.mounted) return;

    if (ok) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(28),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Color(0xFF16A34A), size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Booking Confirmed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Your court has been reserved successfully.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _maroon, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(vm.error ?? 'Booking failed'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.grey.shade100)),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87));
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}