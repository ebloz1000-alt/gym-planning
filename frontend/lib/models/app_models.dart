import 'package:flutter/material.dart';

enum UserRole {
  member('Member'),
  trainer('Trainer'),
  admin('Admin');

  const UserRole(this.label);
  final String label;
}

enum EquipmentStatus {
  available('Available'),
  full('Full'),
  maintenance('Maintenance');

  const EquipmentStatus(this.label);
  final String label;
}

enum BookingStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  completed('Completed'),
  cancelled('Cancelled');

  const BookingStatus(this.label);
  final String label;
}

enum PaymentStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  failed('Failed'),
  expired('Expired'),
  payLater('Pay Later');

  const PaymentStatus(this.label);
  final String label;
}

enum NotificationType {
  booking('Booking', Icons.event_available_outlined),
  membership('Membership', Icons.workspace_premium_outlined),
  payment('Payment', Icons.payments_outlined),
  trainer('Trainer', Icons.fitness_center_outlined),
  reminder('Reminder', Icons.notifications_active_outlined);

  const NotificationType(this.label, this.icon);
  final String label;
  final IconData icon;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.avatarLabel,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String status;
  final String avatarLabel;
  final DateTime joinedAt;

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? status,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      status: status ?? this.status,
      avatarLabel: avatarLabel,
      joinedAt: joinedAt,
    );
  }
}

class MembershipPlan {
  const MembershipPlan({
    required this.name,
    required this.durationDays,
    required this.price,
    required this.features,
    required this.highlight,
  });

  final String name;
  final int durationDays;
  final double price;
  final List<String> features;
  final bool highlight;
}

class MembershipRecord {
  const MembershipRecord({
    required this.plan,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    this.paymentStatus = PaymentStatus.confirmed,
    this.paymentDueAt,
  });

  final String plan;
  final DateTime startedAt;
  final DateTime expiresAt;
  final String status;
  final PaymentStatus paymentStatus;
  final DateTime? paymentDueAt;

  bool get isBookable {
    final now = DateTime.now();
    final paymentOpen =
        paymentStatus != PaymentStatus.payLater ||
        paymentDueAt == null ||
        paymentDueAt!.isAfter(now);
    return status.toLowerCase() == 'active' &&
        expiresAt.isAfter(now) &&
        paymentOpen;
  }

  bool get isPayLater => paymentStatus == PaymentStatus.payLater;

  bool get isPayLaterOverdue {
    final dueAt = paymentDueAt;
    return isPayLater && dueAt != null && !dueAt.isAfter(DateTime.now());
  }

  int get daysRemaining {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 0;
    return (remaining.inMinutes + 1439) ~/ 1440;
  }

  MembershipRecord copyWith({
    String? plan,
    DateTime? startedAt,
    DateTime? expiresAt,
    String? status,
    PaymentStatus? paymentStatus,
    DateTime? paymentDueAt,
  }) {
    return MembershipRecord(
      plan: plan ?? this.plan,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentDueAt: paymentDueAt ?? this.paymentDueAt,
    );
  }
}

class EquipmentItem {
  const EquipmentItem({
    required this.id,
    required this.name,
    required this.category,
    required this.capacity,
    required this.booked,
    required this.status,
    required this.location,
    required this.imageIcon,
    required this.description,
  });

  final String id;
  final String name;
  final String category;
  final int capacity;
  final int booked;
  final EquipmentStatus status;
  final String location;
  final IconData imageIcon;
  final String description;

  int get available => capacity - booked;

  EquipmentItem copyWith({
    String? name,
    String? category,
    int? capacity,
    int? booked,
    EquipmentStatus? status,
    String? location,
    IconData? imageIcon,
    String? description,
  }) {
    return EquipmentItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      capacity: capacity ?? this.capacity,
      booked: booked ?? this.booked,
      status: status ?? this.status,
      location: location ?? this.location,
      imageIcon: imageIcon ?? this.imageIcon,
      description: description ?? this.description,
    );
  }
}

class TrainerProfile {
  const TrainerProfile({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.sessionsToday,
    required this.availableSlots,
    required this.bio,
    required this.status,
  });

  final String id;
  final String name;
  final String specialty;
  final double rating;
  final int sessionsToday;
  final List<String> availableSlots;
  final String bio;
  final String status;

  TrainerProfile copyWith({
    String? id,
    String? name,
    String? specialty,
    double? rating,
    int? sessionsToday,
    List<String>? availableSlots,
    String? bio,
    String? status,
  }) {
    return TrainerProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      rating: rating ?? this.rating,
      sessionsToday: sessionsToday ?? this.sessionsToday,
      availableSlots: availableSlots ?? this.availableSlots,
      bio: bio ?? this.bio,
      status: status ?? this.status,
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.equipmentName,
    required this.trainerName,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.paymentStatus,
  });

  final String id;
  final String equipmentName;
  final String trainerName;
  final DateTime date;
  final String timeSlot;
  final BookingStatus status;
  final PaymentStatus paymentStatus;

  Booking copyWith({
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    String? trainerName,
  }) {
    return Booking(
      id: id,
      equipmentName: equipmentName,
      trainerName: trainerName ?? this.trainerName,
      date: date,
      timeSlot: timeSlot,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.method,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.reference,
  });

  final String id;
  final String method;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;
  final String reference;

  PaymentRecord copyWith({
    String? method,
    double? amount,
    PaymentStatus? status,
    DateTime? createdAt,
    String? reference,
  }) {
    return PaymentRecord(
      id: id,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reference: reference ?? this.reference,
    );
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.target,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String target;
  final int rating;
  final String comment;
  final DateTime createdAt;
}

class AnalyticsPoint {
  const AnalyticsPoint(this.label, this.value);

  final String label;
  final double value;
}

class ReportRow {
  const ReportRow({
    required this.title,
    required this.metric,
    required this.change,
    required this.status,
  });

  final String title;
  final String metric;
  final String change;
  final String status;
}
