// lib/viewmodel/booking_viewmodel.dart

import 'package:flutter/material.dart';
import '../model/booking_model.dart';
import '../model/sport_config_model.dart';
import '../repository/booking_repository.dart';
import '../repository/sport_repository.dart';

class BookingViewModel extends ChangeNotifier {
  final _repo      = BookingRepository();
  final _sportRepo = SportRepository();

  // ── Sport catalogue (loaded from Firestore) ───────────────────────────────
  List<SportConfig> _sportConfigs = [];
  bool _loadingSports = true;

  List<SportConfig> get sportConfigs   => _sportConfigs;
  bool              get loadingSports  => _loadingSports;

  // ── Booking state ─────────────────────────────────────────────────────────
  String    _selectedSport = '';
  DateTime  _selectedDate  = DateTime.now().add(const Duration(days: 1));
  String?   _selectedSlot;
  int?      _selectedCourt;
  bool      _busy          = false;
  String?   _error;
  Set<int>  _bookedCourts  = {};
  bool      _loadingCourts = false;

  Set<String> _eventBlockedDates    = {};
  bool        _loadingBlockedDates  = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  String    get selectedSport       => _selectedSport;
  DateTime  get selectedDate        => _selectedDate;
  String?   get selectedSlot        => _selectedSlot;
  int?      get selectedCourt       => _selectedCourt;
  bool      get busy                => _busy;
  String?   get error               => _error;
  Set<int>  get bookedCourts        => _bookedCourts;
  bool      get loadingCourts       => _loadingCourts;
  Set<String> get eventBlockedDates => _eventBlockedDates;
  bool      get loadingBlockedDates => _loadingBlockedDates;

  SportConfig? get _currentConfig =>
      _sportConfigs.where((s) => s.name == _selectedSport).firstOrNull;

  /// Ordered list of sport names shown in the sport selector chip row.
  List<String> get sports    => _sportConfigs.map((s) => s.name).toList();

  /// Time slots available for the selected sport.
  List<String> get slots     => _currentConfig?.timeSlots ?? [];

  /// Court count for the selected sport.
  int          get courtCount => _currentConfig?.courtCount ?? 0;

  String get dateString =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}';

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isDateEventBlocked(String dateStr) =>
      _eventBlockedDates.contains(dateStr);

  String _toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Constructor ───────────────────────────────────────────────────────────

  BookingViewModel() {
    _initSports();
  }

  Future<void> _initSports() async {
    _loadingSports = true;
    notifyListeners();
    try {
      // Migrate/seed defaults: creates missing sports AND patches stale
      // physical-court config fields (courtStartOffset, etc.) on every start.
      await _sportRepo.migrateDefaults();
      _sportConfigs = await _sportRepo.fetchActiveSports();
      if (_sportConfigs.isNotEmpty) {
        _selectedSport = _sportConfigs.first.name;
      }
    } catch (_) {
      _sportConfigs = [];
    } finally {
      _loadingSports = false;
      notifyListeners();
    }
    if (_selectedSport.isNotEmpty) loadEventBlockedDates();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void setSport(String s) {
    _selectedSport     = s;
    _selectedSlot      = null;
    _selectedCourt     = null;
    _bookedCourts      = {};
    _eventBlockedDates = {};
    notifyListeners();
    loadEventBlockedDates();
  }

  void setDate(DateTime d) {
    if (_eventBlockedDates.contains(_toDateStr(d))) return;
    _selectedDate  = d;
    _selectedSlot  = null;
    _selectedCourt = null;
    _bookedCourts  = {};
    notifyListeners();
  }

  void setSlot(String s) {
    _selectedSlot  = s;
    _selectedCourt = null;
    notifyListeners();
    _loadBookedCourts();
  }

  void setCourt(int c) {
    _selectedCourt = c;
    notifyListeners();
  }

  // ── Async loaders ─────────────────────────────────────────────────────────

  Future<void> loadEventBlockedDates() async {
    if (_selectedSport.isEmpty) return;
    _loadingBlockedDates = true;
    notifyListeners();
    try {
      _eventBlockedDates =
          await _repo.getEventBlockedDates(_selectedSport);
    } catch (_) {
      _eventBlockedDates = {};
    } finally {
      _loadingBlockedDates = false;
      notifyListeners();
    }
  }

  Future<void> _loadBookedCourts() async {
    if (_selectedSlot == null) return;
    _loadingCourts = true;
    notifyListeners();
    try {
      _bookedCourts = await _repo.getBookedCourts(
        sport:    _selectedSport,
        date:     dateString,
        timeSlot: _selectedSlot!,
      );
    } catch (_) {
      _bookedCourts = {};
    } finally {
      _loadingCourts = false;
      notifyListeners();
    }
  }

  // ── Submit booking ────────────────────────────────────────────────────────

  Future<bool> submit({
    required String userId,
    required String userEmail,
  }) async {
    if (_selectedSlot == null || _selectedCourt == null) return false;
    _busy  = true;
    _error = null;
    notifyListeners();
    try {
      final booking = BookingModel(
        id:        '',
        userId:    userId,
        userEmail: userEmail,
        sport:     _selectedSport,
        court:     _selectedCourt!,
        date:      dateString,
        timeSlot:  _selectedSlot!,
        createdAt: DateTime.now(),
      );
      await _repo.submit(booking);
      _selectedSlot  = null;
      _selectedCourt = null;
      _bookedCourts  = {};
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ── Streams ───────────────────────────────────────────────────────────────

  Stream<List<BookingModel>> watchUserBookings(String userId) =>
      _repo.watchUserBookings(userId);

  // ── Helpers ───────────────────────────────────────────────────────────────

  String getMonthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m];
}