import 'package:flutter/material.dart';
import '../model/booking_model.dart';
import '../repository/booking_repository.dart';

class BookingViewModel extends ChangeNotifier {
  final _repo = BookingRepository();

  // State
  String _selectedSport = 'Badminton';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;
  int? _selectedCourt;
  bool _busy = false;
  String? _error;
  Set<int> _bookedCourts = {};
  bool _loadingCourts = false;

  String get selectedSport => _selectedSport;
  DateTime get selectedDate => _selectedDate;
  String? get selectedSlot => _selectedSlot;
  int? get selectedCourt => _selectedCourt;
  bool get busy => _busy;
  String? get error => _error;
  Set<int> get bookedCourts => _bookedCourts;
  bool get loadingCourts => _loadingCourts;

  List<String> get sports => BookingRepository.timeSlots.keys.toList();
  List<String> get slots =>
      BookingRepository.timeSlots[_selectedSport] ?? [];
  int get courtCount =>
      BookingRepository.courtCounts[_selectedSport] ?? 4;

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String get dateString =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  // Setters 
  void setSport(String s) {
    _selectedSport = s;
    _selectedSlot = null;
    _selectedCourt = null;
    _bookedCourts = {};
    notifyListeners();
  }

  void setDate(DateTime d) {
    _selectedDate = d;
    _selectedSlot = null;
    _selectedCourt = null;
    _bookedCourts = {};
    notifyListeners();
  }

  void setSlot(String s) {
    _selectedSlot = s;
    _selectedCourt = null;
    notifyListeners();
    _loadBookedCourts();
  }

  void setCourt(int c) {
    _selectedCourt = c;
    notifyListeners();
  }

  // Load availability 
  Future<void> _loadBookedCourts() async {
    if (_selectedSlot == null) return;
    _loadingCourts = true;
    notifyListeners();
    try {
      _bookedCourts = await _repo.getBookedCourts(
        sport: _selectedSport,
        date: dateString,
        timeSlot: _selectedSlot!,
      );
    } catch (_) {
      _bookedCourts = {};
    } finally {
      _loadingCourts = false;
      notifyListeners();
    }
  }

  // Submit booking
  Future<bool> submit({
    required String userId,
    required String userEmail,
  }) async {
    if (_selectedSlot == null || _selectedCourt == null) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final booking = BookingModel(
        id: '',
        userId: userId,
        userEmail: userEmail,
        sport: _selectedSport,
        court: _selectedCourt!,
        date: dateString,
        timeSlot: _selectedSlot!,
        createdAt: DateTime.now(),
      );
      await _repo.submit(booking);
      // Reset after success
      _selectedSlot = null;
      _selectedCourt = null;
      _bookedCourts = {};
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // User bookings stream 
  Stream<List<BookingModel>> watchUserBookings(String userId) =>
      _repo.watchUserBookings(userId);

  String getMonthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m];
}