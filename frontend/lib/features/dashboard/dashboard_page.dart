import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_helper.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.getResponsivePadding(context);
    final state = AppScope.watch(context);
    final repo = state.repository;
    final user = state.currentUser;
    final nextBooking = repo.bookings.isEmpty ? null : repo.bookings.first;
    final pendingPayments = repo.payments
        .where((payment) => payment.status == PaymentStatus.pending)
        .length;

    return SingleChildScrollView(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back${user == null ? '' : ', ${user.name}'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your gym access, bookings, payments, and alerts are ready.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _QuickStats(
              bookingsCount: repo.bookings.length,
              membership: repo.currentMembership,
              pendingPayments: pendingPayments,
              unreadNotifications: state.unreadNotifications,
            ),
            const SizedBox(height: 24),
            _NextBookingCard(booking: nextBooking),
            const SizedBox(height: 16),
            _MembershipCard(membership: repo.currentMembership),
            const SizedBox(height: 16),
            _PaymentSummaryCard(
              latestPayment: repo.payments.isEmpty ? null : repo.payments.first,
              pendingPayments: pendingPayments,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.bookingsCount,
    required this.membership,
    required this.pendingPayments,
    required this.unreadNotifications,
  });

  final int bookingsCount;
  final MembershipRecord membership;
  final int pendingPayments;
  final int unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final gridCount = ResponsiveHelper.isMobile(context) ? 2 : 4;

    return GridView.count(
      crossAxisCount: gridCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _StatBox(
          title: 'Bookings',
          value: '$bookingsCount active',
          icon: Icons.event_available_outlined,
          color: Colors.teal,
        ),
        _StatBox(
          title: 'Plan',
          value: membership.plan,
          icon: Icons.workspace_premium_outlined,
          color: Colors.indigo,
        ),
        _StatBox(
          title: 'Payments',
          value: '$pendingPayments pending',
          icon: Icons.payments_outlined,
          color: Colors.orange,
        ),
        _StatBox(
          title: 'Alerts',
          value: '$unreadNotifications unread',
          icon: Icons.notifications_active_outlined,
          color: Colors.red,
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({required this.booking});

  final Booking? booking;

  @override
  Widget build(BuildContext context) {
    final booking = this.booking;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Next booking', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (booking == null)
              const Text('No active booking yet.')
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available_outlined),
                title: Text(booking.equipmentName),
                subtitle: Text(
                  '${formatDate(booking.date)} at ${booking.timeSlot}\n'
                  'Trainer: ${booking.trainerName}',
                ),
                isThreeLine: true,
                trailing: Chip(label: Text(booking.status.label)),
              ),
          ],
        ),
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.membership});

  final MembershipRecord membership;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: const Icon(Icons.card_membership_outlined),
        title: Text('${membership.plan} membership'),
        subtitle: Text(
          '${membership.status} until ${formatDate(membership.expiresAt)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.latestPayment,
    required this.pendingPayments,
  });

  final PaymentRecord? latestPayment;
  final int pendingPayments;

  @override
  Widget build(BuildContext context) {
    final payment = latestPayment;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: const Icon(Icons.receipt_long_outlined),
        title: Text('$pendingPayments pending payment(s)'),
        subtitle: Text(
          payment == null
              ? 'No payment history yet.'
              : 'Last payment: ${payment.method} - ${formatMoney(payment.amount)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
