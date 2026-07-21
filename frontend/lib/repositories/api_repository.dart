import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/app_models.dart';

class ApiRepository {
  ApiRepository();

  final http.Client _client = http.Client();

  final List<MembershipPlan> _membershipPlans = <MembershipPlan>[];
  final List<MembershipRecord> _membershipHistory = <MembershipRecord>[];
  final List<EquipmentItem> _equipment = <EquipmentItem>[];
  final List<ReportRow> _reportRows = <ReportRow>[
    const ReportRow(
      title: 'Daily revenue',
      metric: 'KES 0',
      change: 'Pending',
      status: 'Pending',
    ),
    const ReportRow(
      title: 'Trainer performance',
      metric: '0 sessions',
      change: 'Pending',
      status: 'Pending',
    ),
    const ReportRow(
      title: 'Equipment usage',
      metric: '0% utilization',
      change: 'Pending',
      status: 'Pending',
    ),
    const ReportRow(
      title: 'Membership growth',
      metric: '0 active',
      change: 'Pending',
      status: 'Pending',
    ),
  ];
  final Map<String, List<String>> _trainerSchedules = <String, List<String>>{};
  final List<TrainerProfile> _trainers = <TrainerProfile>[];
  final List<Booking> _bookings = <Booking>[];
  final List<PaymentRecord> _payments = <PaymentRecord>[];
  final List<AppNotification> _notifications = <AppNotification>[];
  final List<FeedbackEntry> _feedback = <FeedbackEntry>[];
  final List<AppUser> _users = <AppUser>[];
  final List<AnalyticsPoint> _revenueTrend = <AnalyticsPoint>[];
  final List<AnalyticsPoint> _bookingTrend = <AnalyticsPoint>[];
  final List<AnalyticsPoint> _equipmentUsage = <AnalyticsPoint>[];

  String? _accessToken;
  String? _refreshToken;
  AppUser? _currentUser;
  bool _isAuthenticated = false;

  List<MembershipPlan> get membershipPlans => List.unmodifiable(_membershipPlans);
  List<MembershipRecord> get membershipHistory => List.unmodifiable(_membershipHistory);
  List<EquipmentItem> get equipment => List.unmodifiable(_equipment);
  List<ReportRow> get reportRows => List.unmodifiable(_reportRows);
  List<TrainerProfile> get trainers => List.unmodifiable(_trainers);
  List<Booking> get bookings => List.unmodifiable(_bookings);
  List<PaymentRecord> get payments => List.unmodifiable(_payments);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<FeedbackEntry> get feedback => List.unmodifiable(_feedback);
  List<AppUser> get users => List.unmodifiable(_users);
  List<AnalyticsPoint> get revenueTrend => List.unmodifiable(_revenueTrend);
  List<AnalyticsPoint> get bookingTrend => List.unmodifiable(_bookingTrend);
  List<AnalyticsPoint> get equipmentUsage => List.unmodifiable(_equipmentUsage);

  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated;
  AppUser? get currentUser => _currentUser;

  Future<void> initialize() async {
    await _restoreSession();
    await bootstrap();
  }

  Future<void> bootstrap() async {
    await _loadPublicData();
    if (_isAuthenticated) {
      await loadProfile();
      await _loadProtectedData();
    }
  }

  Future<void> login({required String email, required String password}) async {
    final body = {'email': email, 'password': password};
    final response = await _post('/api/auth/token/', body: body);
    if (response.statusCode != 200) {
      throw _parseError(response, fallback: 'Unable to login.');
    }
    final payload = _decodeJson(response.body);
    _accessToken = payload['access']?.toString();
    _refreshToken = payload['refresh']?.toString();
    _isAuthenticated = _accessToken != null && _accessToken!.isNotEmpty;
    await _persistSession();
    await loadProfile();
    await _loadProtectedData();
  }

  Future<void> register({required String name, required String email, required String phone, required String password}) async {
    final body = {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
    final response = await _post('/api/auth/register/', body: body);
    if (response.statusCode != 201) {
      throw _parseError(response, fallback: 'Unable to create account.');
    }
    final payload = _decodeJson(response.body);
    _accessToken = payload['access']?.toString();
    _refreshToken = payload['refresh']?.toString();
    _isAuthenticated = _accessToken != null && _accessToken!.isNotEmpty;
    await _persistSession();
    await loadProfile();
    await _loadProtectedData();
  }

  Future<void> refreshJwt() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      throw Exception('No refresh token available.');
    }
    final response = await _post('/api/auth/token/refresh/', body: {'refresh': _refreshToken!});
    if (response.statusCode != 200) {
      throw _parseError(response, fallback: 'Unable to refresh session.');
    }
    final payload = _decodeJson(response.body);
    _accessToken = payload['access']?.toString();
    await _persistSession();
    await loadProfile();
  }

  Future<void> loadProfile() async {
    if (!_isAuthenticated) return;
    final response = await _get('/api/auth/me/');
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        _clearSession();
        return;
      }
      throw _parseError(response, fallback: 'Unable to load profile.');
    }
    final payload = _decodeJson(response.body);
    _currentUser = _mapUser(payload);
    _users
      ..clear()
      ..add(_currentUser!);
  }

  Future<void> logout() async {
    _clearSession();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  MembershipRecord get currentMembership {
    final now = DateTime.now();
    return MembershipRecord(
      plan: _membershipPlans.isNotEmpty ? _membershipPlans.first.name : 'Monthly',
      startedAt: now.subtract(const Duration(days: 30)),
      expiresAt: now.add(const Duration(days: 30)),
      status: 'Active',
    );
  }

  MembershipRecord? get activeMembership => null;

  bool get hasBookableMembership => false;

  MembershipPlan membershipPlanByName(String name) {
    return _membershipPlans.firstWhere(
      (plan) => plan.name == name,
      orElse: () => const MembershipPlan(
        name: 'Daily',
        durationDays: 1,
        price: 0,
        features: [],
        highlight: false,
      ),
    );
  }

  List<String> trainerScheduleFor(String trainerId, DateTime date) {
    final key = _dateKey(date);
    final slots = _trainerSchedules[trainerId];
    if (slots == null) return const <String>[];
    return List.unmodifiable(slots.where((slot) => slot == key ? true : true).toList());
  }

  Future<void> renewMembership({required MembershipPlan plan, required int durationDays, required String phone, required double amount}) async {
    final response = await _post(
      '/api/memberships/renew/',
      body: {
        'plan_id': _planIdByName(plan.name),
        'payment_status': 'confirmed',
      },
    );
    if (response.statusCode != 201) {
      throw _parseError(response, fallback: 'Unable to renew membership.');
    }
    await _loadProtectedData();
  }

  Future<void> activateDailyPayLater({required MembershipPlan plan, required int durationDays, required double amount}) async {
    await renewMembership(plan: plan, durationDays: durationDays, phone: '', amount: amount);
  }

  Future<Map<String, dynamic>> initiateStkPush({
    required String phone,
    required double amount,
    required String planName,
    required int durationDays,
    required String accountReference,
  }) async {
    final response = await _post(
      '/api/mpesa/stk_push/',
      body: {
        'phone': phone,
        'amount': amount.toInt(),
        'plan_name': planName,
        'duration_days': durationDays,
        'account_reference': accountReference,
      },
    );
    if (response.statusCode != 200) {
      throw _parseError(response, fallback: 'Unable to send STK request.');
    }
    final payload = _decodeJson(response.body);
    if (payload is Map<String, dynamic> && payload['success'] == true) {
      return payload;
    }
    throw Exception(payload['detail']?.toString() ?? 'Unable to send STK request.');
  }

  void submitCashMembershipPayment({required MembershipPlan plan, required double amount}) {}

  Future<void> _loadPublicData() async {
    final futures = <Future<void>>[
      _loadMembershipPlans(),
      _loadEquipment(),
      _loadTrainers(),
      _loadAnalytics(),
    ];
    await Future.wait(futures);
  }

  Future<void> _loadProtectedData() async {
    if (!_isAuthenticated) return;
    final futures = <Future<void>>[
      _loadBookings(),
      _loadPayments(),
      _loadNotifications(),
      _loadFeedback(),
    ];
    await Future.wait(futures);
  }

  Future<void> _loadMembershipPlans() async {
    final response = await _get('/api/membership-plans/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final items = _listFromJson(payload);
    _membershipPlans
      ..clear()
      ..addAll(items.map(_mapMembershipPlan));
  }

  Future<void> _loadEquipment() async {
    final response = await _get('/api/equipment/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final items = _listFromJson(payload);
    _equipment
      ..clear()
      ..addAll(items.map(_mapEquipment));
  }

  Future<void> _loadTrainers() async {
    final response = await _get('/api/trainers/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final items = _listFromJson(payload);
    _trainers
      ..clear()
      ..addAll(items.map(_mapTrainer));
  }

  Future<void> _loadBookings() async {
    final response = await _get('/api/bookings/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final items = _listFromJson(payload);
    _bookings
      ..clear()
      ..addAll(items.map(_mapBooking));
  }

  Future<void> _loadPayments() async {
    final response = await _get('/api/payments/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final items = _listFromJson(payload);
    _payments
      ..clear()
      ..addAll(items.map(_mapPayment));
  }

  Future<void> _loadNotifications() async {
    final response = await _get('/api/notifications/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final items = _listFromJson(payload);
    _notifications
      ..clear()
      ..addAll(items.map(_mapNotification));
  }

  Future<void> _loadFeedback() async {
    final response = await _get('/api/feedback/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final items = _listFromJson(payload);
    _feedback
      ..clear()
      ..addAll(items.map(_mapFeedback));
  }

  Future<void> _loadAnalytics() async {
    final response = await _get('/api/analytics/');
    if (response.statusCode != 200) return;
    final payload = _decodeJson(response.body);
    final revenue = payload['revenue_trend'] as List<dynamic>? ?? <dynamic>[];
    final booking = payload['booking_trend'] as List<dynamic>? ?? <dynamic>[];
    final usage = payload['equipment_usage'] as List<dynamic>? ?? <dynamic>[];
    _revenueTrend
      ..clear()
      ..addAll(revenue.map((item) => AnalyticsPoint(item['label'].toString(), (item['value'] ?? 0).toDouble())));
    _bookingTrend
      ..clear()
      ..addAll(booking.map((item) => AnalyticsPoint(item['label'].toString(), (item['value'] ?? 0).toDouble())));
    _equipmentUsage
      ..clear()
      ..addAll(usage.map((item) => AnalyticsPoint(item['label'].toString(), (item['value'] ?? 0).toDouble())));
  }

  Future<http.Response> _get(String path) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = <String, String>{'Accept': 'application/json'};
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return _client.get(uri, headers: headers);
  }

  Future<http.Response> _post(String path, {required Map<String, dynamic> body}) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final headers = <String, String>{'Content-Type': 'application/json', 'Accept': 'application/json'};
    final token = _accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return _client.post(uri, headers: headers, body: json.encode(body));
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    _isAuthenticated = _accessToken != null && _accessToken!.isNotEmpty;
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) {
      await prefs.setString('access_token', _accessToken!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
  }

  void _clearSession() {
    _accessToken = null;
    _refreshToken = null;
    _isAuthenticated = false;
    _currentUser = null;
    _users.clear();
  }

  int _planIdByName(String name) {
    final plan = _membershipPlans.firstWhere(
      (item) => item.name == name,
      orElse: () => const MembershipPlan(
        name: 'Daily',
        durationDays: 1,
        price: 0,
        features: [],
        highlight: false,
      ),
    );
    return _membershipPlans.indexOf(plan) + 1;
  }

  MembershipPlan _mapMembershipPlan(dynamic item) {
    final map = item as Map<String, dynamic>;
    return MembershipPlan(
      name: map['name']?.toString() ?? 'Plan',
      durationDays: int.tryParse(map['duration_days']?.toString() ?? '') ?? 0,
      price: double.tryParse(map['price']?.toString() ?? '') ?? 0,
      features: (map['features'] as List?)?.map((feature) => feature.toString()).toList() ?? const <String>[],
      highlight: map['highlight'] == true,
    );
  }

  EquipmentItem _mapEquipment(dynamic item) {
    final map = item as Map<String, dynamic>;
    return EquipmentItem(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      name: map['name']?.toString() ?? 'Equipment',
      category: map['category']?.toString() ?? 'General',
      capacity: int.tryParse(map['capacity']?.toString() ?? '') ?? 1,
      booked: int.tryParse(map['booked']?.toString() ?? '') ?? 0,
      status: _equipmentStatus(map['status']?.toString()),
      location: map['location']?.toString() ?? '',
      imageIcon: Icons.fitness_center_outlined,
      description: map['description']?.toString() ?? '',
    );
  }

  TrainerProfile _mapTrainer(dynamic item) {
    final map = item as Map<String, dynamic>;
    return TrainerProfile(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      name: map['name']?.toString() ?? 'Trainer',
      specialty: map['specialty']?.toString() ?? 'General',
      rating: double.tryParse(map['rating']?.toString() ?? '') ?? 0,
      sessionsToday: int.tryParse(map['sessions_today']?.toString() ?? '') ?? 0,
      availableSlots: (map['available_slots'] as List?)?.map((slot) => slot.toString()).toList() ?? const <String>[],
      bio: map['bio']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Available',
    );
  }

  Booking _mapBooking(dynamic item) {
    final map = item as Map<String, dynamic>;
    return Booking(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      equipmentName: map['equipment_name']?.toString() ?? 'Equipment',
      trainerName: map['trainer_name']?.toString() ?? 'Trainer',
      date: DateTime.parse(map['date']?.toString() ?? DateTime.now().toIso8601String()),
      timeSlot: map['time_slot']?.toString() ?? '',
      status: _bookingStatus(map['status']?.toString()),
      paymentStatus: _paymentStatus(map['payment_status']?.toString()),
    );
  }

  PaymentRecord _mapPayment(dynamic item) {
    final map = item as Map<String, dynamic>;
    return PaymentRecord(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      method: map['method']?.toString() ?? 'Unknown',
      amount: double.tryParse(map['amount']?.toString() ?? '') ?? 0,
      status: _paymentStatus(map['status']?.toString()),
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      reference: map['reference']?.toString() ?? '',
    );
  }

  AppNotification _mapNotification(dynamic item) {
    final map = item as Map<String, dynamic>;
    return AppNotification(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      type: _notificationType(map['type']?.toString()),
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
      isRead: map['is_read'] == true,
    );
  }

  FeedbackEntry _mapFeedback(dynamic item) {
    final map = item as Map<String, dynamic>;
    return FeedbackEntry(
      id: map['id']?.toString() ?? UniqueKey().toString(),
      target: map['target']?.toString() ?? 'Gym',
      rating: int.tryParse(map['rating']?.toString() ?? '') ?? 0,
      comment: map['comment']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  AppUser _mapUser(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? 'user',
      name: map['name']?.toString() ?? 'Gym Member',
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      role: _userRole(map['role']?.toString()),
      status: map['status']?.toString() ?? 'Active',
      avatarLabel: map['avatar_label']?.toString() ?? '',
      joinedAt: DateTime.parse(map['joined_at']?.toString() ?? DateTime.now().toIso8601String()),
    );
  }

  UserRole _userRole(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'trainer':
        return UserRole.trainer;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.member;
    }
  }

  EquipmentStatus _equipmentStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'full':
        return EquipmentStatus.full;
      case 'maintenance':
        return EquipmentStatus.maintenance;
      default:
        return EquipmentStatus.available;
    }
  }

  BookingStatus _bookingStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  PaymentStatus _paymentStatus(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'confirmed':
        return PaymentStatus.confirmed;
      case 'failed':
        return PaymentStatus.failed;
      case 'expired':
        return PaymentStatus.expired;
      case 'paylater':
      case 'pay later':
        return PaymentStatus.payLater;
      default:
        return PaymentStatus.pending;
    }
  }

  NotificationType _notificationType(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'membership':
        return NotificationType.membership;
      case 'payment':
        return NotificationType.payment;
      case 'trainer':
        return NotificationType.trainer;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.booking;
    }
  }

  dynamic _decodeJson(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<dynamic> _listFromJson(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map<String, dynamic> && payload['results'] is List) return payload['results'] as List<dynamic>;
    return <dynamic>[];
  }

  Exception _parseError(http.Response response, {required String fallback}) {
    final decoded = _decodeJson(response.body);
    final detail = decoded is Map<String, dynamic> ? decoded['detail'] : null;
    return Exception(detail?.toString() ?? fallback);
  }

  void addBooking(Booking booking) {
    _bookings.insert(0, booking);
  }

  void updateBooking(Booking booking) {
    final index = _bookings.indexWhere((item) => item.id == booking.id);
    if (index != -1) {
      _bookings[index] = booking;
    }
  }

  void addPayment(PaymentRecord payment) {
    _payments.insert(0, payment);
  }

  void updatePayment(PaymentRecord payment) {
    final index = _payments.indexWhere((item) => item.id == payment.id);
    if (index != -1) {
      _payments[index] = payment;
    }
  }

  void addEquipment(EquipmentItem item) {
    _equipment.insert(0, item);
  }

  void updateEquipment(EquipmentItem item) {
    final index = _equipment.indexWhere((existing) => existing.id == item.id);
    if (index != -1) {
      _equipment[index] = item;
    }
  }

  bool saveTrainerAvailability({required String trainerId, required String slot}) {
    final index = _trainers.indexWhere((trainer) => trainer.id == trainerId);
    if (index == -1) return false;
    final trainer = _trainers[index];
    if (trainer.availableSlots.contains(slot)) return false;
    _trainers[index] = trainer.copyWith(availableSlots: [...trainer.availableSlots, slot]);
    return true;
  }

  bool removeTrainerAvailability({required String trainerId, required String slot}) {
    final index = _trainers.indexWhere((trainer) => trainer.id == trainerId);
    if (index == -1) return false;
    final trainer = _trainers[index];
    if (!trainer.availableSlots.contains(slot)) return false;
    final updatedSlots = trainer.availableSlots.where((item) => item != slot).toList();
    _trainers[index] = trainer.copyWith(availableSlots: updatedSlots);
    return true;
  }

  bool saveTrainerSchedule({required String trainerId, required DateTime date, required String slot}) {
    final availabilityUpdated = saveTrainerAvailability(trainerId: trainerId, slot: slot);
    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final scheduleForTrainer = <String, List<String>>{};
    final existing = _trainers.indexWhere((trainer) => trainer.id == trainerId);
    if (existing != -1) {
      scheduleForTrainer[dateKey] = [slot];
    }
    return availabilityUpdated || scheduleForTrainer[dateKey]!.contains(slot);
  }

  TrainerProfile? trainerProfileForUser(AppUser user) {
    try {
      return _trainers.firstWhere((trainer) => trainer.name == user.name);
    } catch (_) {
      return null;
    }
  }

  void deleteEquipment(EquipmentItem item) {
    _equipment.removeWhere((existing) => existing.id == item.id);
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  void addFeedback(FeedbackEntry entry) {
    _feedback.insert(0, entry);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void updateUser(AppUser user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }

  int expireOverduePayLater(DateTime now) {
    return 0;
  }
}
