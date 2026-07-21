import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

String formatMoney(num value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    final reverseIndex = rounded.length - i;
    buffer.write(rounded[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${AppConstants.currency} $buffer';
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatShortDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${weekdays[date.weekday - 1]} ${date.day}';
}

String formatCountdown(DateTime expiry) {
  final days = expiry.difference(DateTime.now()).inDays;
  if (days < 0) return 'Expired';
  if (days == 0) return 'Expires today';
  return '$days days left';
}

String formatTimeLeft(DateTime expiry) {
  final remaining = expiry.difference(DateTime.now());
  if (remaining.isNegative) return 'Expired';
  final days = remaining.inDays;
  final hours = remaining.inHours % 24;
  final minutes = remaining.inMinutes % 60;

  if (days > 0) {
    return '$days days ${hours}h ${minutes}m left';
  }
  if (hours > 0) {
    return '$hours hours ${minutes}m left';
  }
  if (minutes > 0) {
    return '$minutes minutes left';
  }
  return 'Less than a minute left';
}

Color statusColor(BuildContext context, String status) {
  final scheme = Theme.of(context).colorScheme;
  switch (status.toLowerCase()) {
    case 'available':
    case 'active':
    case 'confirmed':
    case 'paid':
    case 'completed':
      return Colors.green.shade700;
    case 'pending':
    case 'due':
    case 'pay later':
      return Colors.amber.shade800;
    case 'maintenance':
    case 'cancelled':
    case 'failed':
    case 'expired':
    case 'blocked':
      return scheme.error;
    case 'full':
    case 'busy':
      return Colors.deepOrange.shade700;
    default:
      return scheme.primary;
  }
}
