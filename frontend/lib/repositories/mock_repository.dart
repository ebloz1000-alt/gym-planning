import 'package:flutter/material.dart';

import '../models/app_models.dart';

class MockRepository {
  MockRepository();

  final List<AppUser> _users = [
    AppUser(
      id: 'u-1001',
      name: 'Amina Otieno',
      email: 'amina@example.com',
      phone: '+254 711 245 901',
      role: UserRole.member,
      status: 'Active',
      avatarLabel: 'AO',
      joinedAt: DateTime.now().subtract(const Duration(days: 82)),
    ),
    AppUser(
      id: 'u-2001',
      name: 'Brian Kariuki',
      email: 'brian.trainer@example.com',
      phone: '+254 712 883 220',
      role: UserRole.trainer,
      status: 'Active',
      avatarLabel: 'BK',
      joinedAt: DateTime.now().subtract(const Duration(days: 180)),
    ),
    AppUser(
      id: 'u-3001',
      name: 'Grace Admin',
      email: 'admin@example.com',
      phone: '+254 733 101 303',
      role: UserRole.admin,
      status: 'Active',
      avatarLabel: 'GA',
      joinedAt: DateTime.now().subtract(const Duration(days: 365)),
    ),
    AppUser(
      id: 'u-1002',
      name: 'Kevin Njoroge',
      email: 'kevin@example.com',
      phone: '+254 722 013 444',
      role: UserRole.member,
      status: 'Suspended',
      avatarLabel: 'KN',
      joinedAt: DateTime.now().subtract(const Duration(days: 44)),
    ),
    AppUser(
      id: 'u-2002',
      name: 'Maya Wanjiku',
      email: 'maya.trainer@example.com',
      phone: '+254 700 999 201',
      role: UserRole.trainer,
      status: 'Active',
      avatarLabel: 'MW',
      joinedAt: DateTime.now().subtract(const Duration(days: 123)),
    ),
  ];

  final List<MembershipPlan> membershipPlans = const [
    MembershipPlan(
      name: 'Daily',
      durationDays: 1,
      price: 400,
      highlight: false,
      features: [
        'Single day access',
        'Equipment booking',
        'Pay Later until 12:00 PM',
      ],
    ),
    MembershipPlan(
      name: 'Weekly',
      durationDays: 7,
      price: 2200,
      highlight: false,
      features: ['7-day access', '2 trainer sessions', 'Booking priority'],
    ),
    MembershipPlan(
      name: 'Monthly',
      durationDays: 30,
      price: 6800,
      highlight: true,
      features: ['Unlimited access', '8 trainer sessions', 'Progress review'],
    ),
    MembershipPlan(
      name: 'VIP',
      durationDays: 45,
      price: 12000,
      highlight: false,
      features: ['Flexible duration', 'Premium trainer slots', 'VIP support'],
    ),
  ];

  final List<MembershipRecord> membershipHistory = [
    MembershipRecord(
      plan: 'Monthly',
      startedAt: DateTime.now().subtract(const Duration(days: 18)),
      expiresAt: DateTime.now().add(const Duration(days: 12)),
      status: 'Active',
    ),
    MembershipRecord(
      plan: 'Weekly',
      startedAt: DateTime.now().subtract(const Duration(days: 42)),
      expiresAt: DateTime.now().subtract(const Duration(days: 35)),
      status: 'Completed',
    ),
    MembershipRecord(
      plan: 'Daily',
      startedAt: DateTime.now().subtract(const Duration(days: 68)),
      expiresAt: DateTime.now().subtract(const Duration(days: 67)),
      status: 'Completed',
    ),
  ];

  final List<EquipmentItem> _equipment = [
    EquipmentItem(
      id: 'eq-1',
      name: 'Treadmill Pro X',
      category: 'Cardio',
      capacity: 10,
      booked: 6,
      status: EquipmentStatus.available,
      location: 'Cardio Zone A',
      imageIcon: Icons.directions_run_outlined,
      description: 'High-incline treadmill with heart rate monitoring.',
    ),
    EquipmentItem(
      id: 'eq-2',
      name: 'Olympic Bench Press',
      category: 'Strength',
      capacity: 4,
      booked: 4,
      status: EquipmentStatus.full,
      location: 'Strength Bay 2',
      imageIcon: Icons.fitness_center_outlined,
      description: 'Adjustable bench setup for barbell strength programs.',
    ),
    EquipmentItem(
      id: 'eq-3',
      name: 'Cable Crossover',
      category: 'Functional',
      capacity: 6,
      booked: 2,
      status: EquipmentStatus.available,
      location: 'Functional Studio',
      imageIcon: Icons.cable_outlined,
      description: 'Dual-pulley station for guided movement training.',
    ),
    EquipmentItem(
      id: 'eq-4',
      name: 'Spin Bike Row',
      category: 'Cardio',
      capacity: 16,
      booked: 11,
      status: EquipmentStatus.available,
      location: 'Studio B',
      imageIcon: Icons.pedal_bike_outlined,
      description: 'Group cycling bikes with resistance calibration.',
    ),
    EquipmentItem(
      id: 'eq-5',
      name: 'Assault AirBike',
      category: 'Cardio',
      capacity: 3,
      booked: 0,
      status: EquipmentStatus.maintenance,
      location: 'Maintenance Hold',
      imageIcon: Icons.air_outlined,
      description: 'Full-body conditioning bikes undergoing service.',
    ),
    EquipmentItem(
      id: 'eq-6',
      name: 'Recovery Boots',
      category: 'Recovery',
      capacity: 5,
      booked: 1,
      status: EquipmentStatus.available,
      location: 'Recovery Lounge',
      imageIcon: Icons.self_improvement_outlined,
      description: 'Compression recovery equipment for post-session care.',
    ),
  ];

  final List<TrainerProfile> trainers = [
    TrainerProfile(
      id: 'tr-1',
      name: 'Brian Kariuki',
      specialty: 'Strength & Hypertrophy',
      rating: 4.9,
      sessionsToday: 5,
      availableSlots: ['07:00', '12:00', '18:00'],
      status: 'Available',
      bio:
          'Structured strength coaching with technique audits and progression.',
    ),
    TrainerProfile(
      id: 'tr-2',
      name: 'Maya Wanjiku',
      specialty: 'Cardio Conditioning',
      rating: 4.8,
      sessionsToday: 4,
      availableSlots: ['06:00', '10:00', '16:00'],
      status: 'Available',
      bio: 'Endurance, fat-loss, and heart-rate-zone programming specialist.',
    ),
    TrainerProfile(
      id: 'tr-3',
      name: 'Leo Mutua',
      specialty: 'Mobility & Recovery',
      rating: 4.7,
      sessionsToday: 6,
      availableSlots: ['08:00', '14:00', '20:00'],
      status: 'Busy',
      bio: 'Mobility screens, corrective exercise, and recovery planning.',
    ),
  ];

  final Map<String, Map<String, List<String>>> _trainerSchedules = {};

  final List<Booking> _bookings = [
    Booking(
      id: 'bk-1001',
      equipmentName: 'Treadmill Pro X',
      trainerName: 'Maya Wanjiku',
      date: DateTime.now(),
      timeSlot: '18:00',
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.confirmed,
    ),
    Booking(
      id: 'bk-1002',
      equipmentName: 'Cable Crossover',
      trainerName: 'Brian Kariuki',
      date: DateTime.now().add(const Duration(days: 1)),
      timeSlot: '07:00',
      status: BookingStatus.pending,
      paymentStatus: PaymentStatus.pending,
    ),
    Booking(
      id: 'bk-1003',
      equipmentName: 'Spin Bike Row',
      trainerName: 'Maya Wanjiku',
      date: DateTime.now().subtract(const Duration(days: 2)),
      timeSlot: '10:00',
      status: BookingStatus.completed,
      paymentStatus: PaymentStatus.confirmed,
    ),
    Booking(
      id: 'bk-1004',
      equipmentName: 'Olympic Bench Press',
      trainerName: 'Brian Kariuki',
      date: DateTime.now().add(const Duration(days: 3)),
      timeSlot: '16:00',
      status: BookingStatus.confirmed,
      paymentStatus: PaymentStatus.payLater,
    ),
  ];

  final List<PaymentRecord> _payments = [
    PaymentRecord(
      id: 'pay-1001',
      method: 'M-Pesa STK',
      amount: 6800,
      status: PaymentStatus.confirmed,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
      reference: 'MPESA-Q2F9X1',
    ),
    PaymentRecord(
      id: 'pay-1002',
      method: 'Pay Later',
      amount: 1200,
      status: PaymentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      reference: 'LATER-4582',
    ),
    PaymentRecord(
      id: 'pay-1003',
      method: 'Cash',
      amount: 400,
      status: PaymentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      reference: 'CASH-9044',
    ),
  ];

  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'nt-1',
      type: NotificationType.booking,
      title: 'Booking confirmed',
      message: 'Your Treadmill Pro X session is confirmed for 18:00 today.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      isRead: false,
    ),
    AppNotification(
      id: 'nt-2',
      type: NotificationType.membership,
      title: 'Membership expires soon',
      message: 'Your Monthly plan has 12 days remaining.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
    ),
    AppNotification(
      id: 'nt-3',
      type: NotificationType.payment,
      title: 'Payment pending',
      message: 'Complete your Pay Later balance before your next session.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: true,
    ),
    AppNotification(
      id: 'nt-4',
      type: NotificationType.trainer,
      title: 'Trainer schedule updated',
      message: 'Brian added an extra evening slot tomorrow.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
  ];

  final List<FeedbackEntry> _feedback = [
    FeedbackEntry(
      id: 'fb-1',
      target: 'Brian Kariuki',
      rating: 5,
      comment: 'Great technique correction and clear pacing.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    FeedbackEntry(
      id: 'fb-2',
      target: 'Treadmill Pro X',
      rating: 4,
      comment: 'Clean and reliable, one unit had a noisy belt.',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
  ];

  final List<AnalyticsPoint> revenueTrend = const [
    AnalyticsPoint('Mon', 44),
    AnalyticsPoint('Tue', 58),
    AnalyticsPoint('Wed', 72),
    AnalyticsPoint('Thu', 69),
    AnalyticsPoint('Fri', 91),
    AnalyticsPoint('Sat', 105),
    AnalyticsPoint('Sun', 76),
  ];

  final List<AnalyticsPoint> bookingTrend = const [
    AnalyticsPoint('6a', 18),
    AnalyticsPoint('8a', 35),
    AnalyticsPoint('10a', 28),
    AnalyticsPoint('12p', 21),
    AnalyticsPoint('4p', 42),
    AnalyticsPoint('6p', 64),
    AnalyticsPoint('8p', 39),
  ];

  final List<AnalyticsPoint> equipmentUsage = const [
    AnalyticsPoint('Cardio', 82),
    AnalyticsPoint('Strength', 68),
    AnalyticsPoint('Functional', 51),
    AnalyticsPoint('Recovery', 33),
  ];

  final List<ReportRow> reportRows = const [
    ReportRow(
      title: 'Daily revenue',
      metric: 'KES 74,200',
      change: '+12%',
      status: 'Ready',
    ),
    ReportRow(
      title: 'Trainer performance',
      metric: '42 sessions',
      change: '+8%',
      status: 'Ready',
    ),
    ReportRow(
      title: 'Equipment usage',
      metric: '74% utilization',
      change: '-3%',
      status: 'Review',
    ),
    ReportRow(
      title: 'Membership growth',
      metric: '126 active',
      change: '+16%',
      status: 'Ready',
    ),
  ];

  List<AppUser> get users => List.unmodifiable(_users);
  List<EquipmentItem> get equipment => List.unmodifiable(_equipment);
  List<Booking> get bookings => List.unmodifiable(_bookings);
  List<PaymentRecord> get payments => List.unmodifiable(_payments);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<FeedbackEntry> get feedback => List.unmodifiable(_feedback);

  AppUser userForRole(UserRole role) =>
      _users.firstWhere((user) => user.role == role);

  MembershipRecord get currentMembership => membershipHistory.first;
  MembershipRecord? get activeMembership {
    for (final membership in membershipHistory) {
      if (membership.isBookable) return membership;
    }
    return null;
  }

  bool get hasBookableMembership => activeMembership != null;

  MembershipPlan membershipPlanByName(String name) {
    return membershipPlans.firstWhere((plan) => plan.name == name);
  }

  MembershipRecord renewMembership({
    required MembershipPlan plan,
    required int durationDays,
    PaymentStatus paymentStatus = PaymentStatus.confirmed,
    DateTime? paymentDueAt,
  }) {
    final now = DateTime.now();
    final record = MembershipRecord(
      plan: plan.name,
      startedAt: now,
      expiresAt: now.add(Duration(days: durationDays)),
      status: 'Active',
      paymentStatus: paymentStatus,
      paymentDueAt: paymentDueAt,
    );
    membershipHistory.insert(0, record);
    return record;
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

  int expireOverduePayLater(DateTime now) {
    if (membershipHistory.isEmpty) return 0;
    final current = membershipHistory.first;
    final dueAt = current.paymentDueAt;
    if (current.paymentStatus != PaymentStatus.payLater ||
        dueAt == null ||
        dueAt.isAfter(now)) {
      return 0;
    }

    membershipHistory[0] = current.copyWith(
      status: 'Expired',
      paymentStatus: PaymentStatus.expired,
    );

    final beforeBookings = _bookings.length;
    _bookings.removeWhere(
      (booking) =>
          booking.paymentStatus == PaymentStatus.payLater &&
          booking.status != BookingStatus.completed,
    );

    for (var i = 0; i < _payments.length; i++) {
      final payment = _payments[i];
      if (payment.method == 'Pay Later' &&
          payment.status == PaymentStatus.pending &&
          !payment.createdAt.isAfter(dueAt)) {
        _payments[i] = payment.copyWith(status: PaymentStatus.expired);
      }
    }

    return 1 + beforeBookings - _bookings.length;
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

  void updateTrainer(TrainerProfile trainer) {
    final index = trainers.indexWhere((item) => item.id == trainer.id);
    if (index != -1) {
      trainers[index] = trainer;
    }
  }

  bool saveTrainerAvailability({
    required String trainerId,
    required String slot,
  }) {
    final index = trainers.indexWhere((trainer) => trainer.id == trainerId);
    if (index == -1) return false;
    final trainer = trainers[index];
    if (trainer.availableSlots.contains(slot)) {
      return false;
    }
    trainers[index] = trainer.copyWith(
      availableSlots: [...trainer.availableSlots, slot],
    );
    return true;
  }

  bool removeTrainerAvailability({
    required String trainerId,
    required String slot,
  }) {
    final index = trainers.indexWhere((trainer) => trainer.id == trainerId);
    if (index == -1) return false;
    final trainer = trainers[index];
    if (!trainer.availableSlots.contains(slot)) {
      return false;
    }
    final updatedSlots = trainer.availableSlots.where((item) => item != slot).toList();
    trainers[index] = trainer.copyWith(availableSlots: updatedSlots);
    return true;
  }

  bool saveTrainerSchedule({
    required String trainerId,
    required DateTime date,
    required String slot,
  }) {
    final availabilityUpdated = saveTrainerAvailability(
      trainerId: trainerId,
      slot: slot,
    );
    final dateKey = _dateKey(date);
    final scheduleForTrainer = _trainerSchedules.putIfAbsent(trainerId, () => {});
    final slots = scheduleForTrainer.putIfAbsent(dateKey, () => []);
    final scheduleAdded = !slots.contains(slot);
    if (scheduleAdded) {
      slots.add(slot);
    }
    return scheduleAdded || availabilityUpdated;
  }

  List<String> trainerScheduleFor(String trainerId, DateTime date) {
    final scheduleForTrainer = _trainerSchedules[trainerId];
    if (scheduleForTrainer == null) return const [];
    return List.unmodifiable(scheduleForTrainer[_dateKey(date)] ?? []);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  TrainerProfile? trainerProfileForUser(AppUser user) {
    try {
      return trainers.firstWhere((trainer) => trainer.name == user.name);
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

  void updateUser(AppUser user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index != -1) {
      _users[index] = user;
    }
  }
}
