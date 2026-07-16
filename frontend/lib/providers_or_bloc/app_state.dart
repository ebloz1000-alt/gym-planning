import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/app_models.dart';
import '../repositories/mock_repository.dart';

class AppState extends ChangeNotifier {
  AppState();

  final MockRepository repository = MockRepository();
  Timer? _payLaterSweepTimer;

  bool isBootstrapped = false;
  bool hasInternet = true;
  bool hasCompletedOnboarding = false;
  bool rememberMe = false;
  bool isRefreshingSession = false;
  bool notificationsEnabled = true;
  String jwtStatus = 'Not checked';
  String appVersionStatus = 'Ready';

  UserRole? currentRole;
  AppUser? currentUser;
  ThemeMode themeMode = ThemeMode.light;
  String language = 'English';

  Future<void> bootstrap() async {
    if (isBootstrapped) return;
    appVersionStatus = 'Checking version';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    hasInternet = true;
    appVersionStatus = 'Version up to date';
    jwtStatus = 'No saved JWT token';
    await Future<void>.delayed(const Duration(milliseconds: 450));
    enforcePayLaterDeadline(notify: false);
    _startPayLaterDeadlineSweep();
    isBootstrapped = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _payLaterSweepTimer?.cancel();
    super.dispose();
  }

  Future<void> login(UserRole role, {required bool remember}) async {
    isRefreshingSession = true;
    rememberMe = remember;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 650));
    currentRole = role;
    currentUser = repository.userForRole(role);
    jwtStatus = remember ? 'JWT stored and valid' : 'Session token valid';
    isRefreshingSession = false;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    const role = UserRole.member;
    currentRole = role;
    currentUser = AppUser(
      id: 'new-${DateTime.now().millisecondsSinceEpoch}',
      name: name.isEmpty ? 'New ${role.label}' : name,
      email: email.isEmpty ? 'new-user@example.com' : email,
      phone: phone.isEmpty ? '+254 700 123 456' : phone,
      role: role,
      status: 'Active',
      avatarLabel: _initials(name.isEmpty ? role.label : name),
      joinedAt: DateTime.now(),
    );
    jwtStatus = 'JWT issued after registration';
    notifyListeners();
  }

  Future<void> refreshJwt() async {
    isRefreshingSession = true;
    jwtStatus = 'Refreshing JWT';
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 550));
    jwtStatus = 'JWT refreshed just now';
    isRefreshingSession = false;
    notifyListeners();
  }

  void completeOnboarding() {
    hasCompletedOnboarding = true;
    notifyListeners();
  }

  void logout() {
    currentRole = null;
    currentUser = null;
    jwtStatus = 'Logged out and token cleared';
    notifyListeners();
  }

  void switchRole(UserRole role) {
    currentRole = role;
    currentUser = repository.userForRole(role);
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void setNotificationsEnabled(bool value) {
    notificationsEnabled = value;
    notifyListeners();
  }

  void addBooking(Booking booking) {
    enforcePayLaterDeadline(notify: false);
    repository.addBooking(booking);
    notifyListeners();
  }

  void cancelBooking(Booking booking) {
    repository.updateBooking(booking.copyWith(status: BookingStatus.cancelled));
    notifyListeners();
  }

  void updateBooking(Booking booking) {
    repository.updateBooking(booking);
    notifyListeners();
  }

  void overrideBooking(Booking booking) {
    repository.updateBooking(booking.copyWith(status: BookingStatus.confirmed));
    notifyListeners();
  }

  void addPayment(PaymentRecord payment) {
    repository.addPayment(payment);
    notifyListeners();
  }

  void updatePayment(PaymentRecord payment) {
    repository.updatePayment(payment);
    notifyListeners();
  }

  void addEquipment(EquipmentItem item) {
    repository.addEquipment(item);
    notifyListeners();
  }

  void updateEquipment(EquipmentItem item) {
    repository.updateEquipment(item);
    notifyListeners();
  }

  TrainerProfile? get currentTrainerProfile =>
      currentRole == UserRole.trainer && currentUser != null
          ? repository.trainerProfileForUser(currentUser!)
          : null;

  bool saveTrainerAvailability({
    required String trainerId,
    required String slot,
  }) {
    final saved = repository.saveTrainerAvailability(
      trainerId: trainerId,
      slot: slot,
    );
    if (saved) notifyListeners();
    return saved;
  }

  bool withdrawTrainerAvailability({
    required String trainerId,
    required String slot,
  }) {
    final withdrawn = repository.removeTrainerAvailability(
      trainerId: trainerId,
      slot: slot,
    );
    if (withdrawn) notifyListeners();
    return withdrawn;
  }

  bool saveTrainerSchedule({
    required String trainerId,
    required DateTime date,
    required String slot,
  }) {
    final saved = repository.saveTrainerSchedule(
      trainerId: trainerId,
      date: date,
      slot: slot,
    );
    if (saved) notifyListeners();
    return saved;
  }

  void deleteEquipment(EquipmentItem item) {
    repository.deleteEquipment(item);
    notifyListeners();
  }

  Future<void> renewMembership({
    required MembershipPlan plan,
    required int durationDays,
    required String phone,
    required double amount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final membership = repository.renewMembership(
      plan: plan,
      durationDays: durationDays,
    );
    repository.addPayment(
      PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        method: 'M-Pesa STK',
        amount: amount,
        status: PaymentStatus.confirmed,
        createdAt: DateTime.now(),
        reference:
            'STK-${membership.plan.toUpperCase()}-${phone.hashCode.abs()}',
      ),
    );
    notifyListeners();
  }

  Future<void> activateDailyPayLater({
    required MembershipPlan plan,
    required int durationDays,
    required double amount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final dueAt = _nextNoon(DateTime.now());
    repository.renewMembership(
      plan: plan,
      durationDays: durationDays,
      paymentStatus: PaymentStatus.payLater,
      paymentDueAt: dueAt,
    );
    repository.addPayment(
      PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        method: 'Pay Later',
        amount: amount,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        reference: 'LATER-${plan.name.toUpperCase()}-${dueAt.hour}00',
      ),
    );
    notifyListeners();
  }

  void submitCashMembershipPayment({
    required MembershipPlan plan,
    required double amount,
  }) {
    repository.addPayment(
      PaymentRecord(
        id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
        method: 'Cash',
        amount: amount,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
        reference:
            'CASH-${plan.name.toUpperCase()}-${DateTime.now().second}${DateTime.now().millisecond}',
      ),
    );
    notifyListeners();
  }

  void approveCashPaymentForMembership({
    required PaymentRecord payment,
    required MembershipPlan plan,
    required int durationDays,
  }) {
    repository.updatePayment(payment.copyWith(status: PaymentStatus.confirmed));
    repository.renewMembership(plan: plan, durationDays: durationDays);
    notifyListeners();
  }

  int enforcePayLaterDeadline({bool notify = true}) {
    final removed = repository.expireOverduePayLater(DateTime.now());
    if (removed > 0 && notify) notifyListeners();
    return removed;
  }

  void markNotificationRead(String id) {
    repository.markNotificationRead(id);
    notifyListeners();
  }

  void addFeedback(FeedbackEntry entry) {
    repository.addFeedback(entry);
    notifyListeners();
  }

  void updateProfile(AppUser user) {
    currentUser = user;
    repository.updateUser(user);
    notifyListeners();
  }

  int get unreadNotifications =>
      repository.notifications.where((item) => !item.isRead).length;

  MembershipRecord? get activeMembership => repository.activeMembership;

  bool get hasBookableMembership => repository.hasBookableMembership;

  void _startPayLaterDeadlineSweep() {
    _payLaterSweepTimer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      enforcePayLaterDeadline();
    });
  }

  DateTime _nextNoon(DateTime now) {
    final todayNoon = DateTime(now.year, now.month, now.day, 12);
    if (now.isBefore(todayNoon)) return todayNoon;
    return todayNoon.add(const Duration(days: 1));
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'FF';
    if (parts.length == 1) {
      final end = parts.first.length < 2 ? parts.first.length : 2;
      return parts.first.substring(0, end).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final state = AppState();
  unawaited(state.bootstrap());
  return state;
});

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<AppScope>();
    final scope = element?.widget as AppScope?;
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
