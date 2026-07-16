import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';
import '../../core/utils/report_export.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({
    super.key,
    this.onQuickBook,
    this.onRenew,
    this.onFeedback,
  });

  final VoidCallback? onQuickBook;
  final VoidCallback? onRenew;
  final VoidCallback? onFeedback;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final repo = state.repository;
    final membership = state.activeMembership;
    final upcoming = repo.bookings
        .where((booking) => booking.status != BookingStatus.completed)
        .take(3)
        .toList();
    final today = repo.bookings.where((booking) {
      return DateUtils.isSameDay(booking.date, DateTime.now());
    }).toList();
    return FeaturePage(
      title: 'Member Home',
      subtitle:
          'Hi ${state.currentUser?.name ?? 'Member'}, here is your gym day.',
      trailing: StatusBadge(label: membership?.status ?? 'No membership'),
      children: [
        ResponsiveGrid(
          children: [
            StatCard(
              label: 'Membership',
              value: membership == null
                  ? 'No active membership'
                  : '${membership.plan} member',
              icon: Icons.workspace_premium_outlined,
              change: membership == null ? 'None' : 'Active',
            ),
            StatCard(
              label: 'Today bookings',
              value: '${today.length}',
              icon: Icons.event_available_outlined,
              change: today.isEmpty ? 'Due' : 'Confirmed',
            ),
            StatCard(
              label: 'Equipment available',
              value: '${repo.equipment.where((e) => e.available > 0).length}',
              icon: Icons.fitness_center_outlined,
              change: 'Available',
            ),
            StatCard(
              label: 'Unread alerts',
              value: '${state.unreadNotifications}',
              icon: Icons.notifications_none_outlined,
              change: state.unreadNotifications == 0 ? 'Read' : 'Pending',
            ),
          ],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (membership == null) ...[
                Row(
                  children: const [
                    Icon(Icons.credit_card_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No membership selected',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('Select a membership plan to see countdown and booking access.'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppButton(
                      label: 'Select Membership',
                      icon: Icons.workspace_premium_outlined,
                      onPressed: onRenew,
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.credit_card_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${membership.plan} Membership Card',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(label: membership.status),
                    if (membership.paymentStatus != PaymentStatus.confirmed) ...[
                      const SizedBox(width: 8),
                      StatusBadge(label: membership.paymentStatus.label),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text('Expires on ${formatDate(membership.expiresAt)}'),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.64,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AppButton(
                      label: 'Quick Book',
                      icon: Icons.event_available_outlined,
                      onPressed: () => _handleQuickBook(context, state),
                    ),
                    AppButton(
                      label: 'Export PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      onPressed: () => _exportMembership(context, 'PDF', membership),
                    ),
                    AppButton(
                      label: 'Export Excel',
                      icon: Icons.table_chart_outlined,
                      onPressed: () => _exportMembership(context, 'Excel', membership),
                    ),
                    AppButton(
                      label: 'Renew',
                      icon: Icons.restart_alt_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: onRenew,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SectionHeader(title: 'Upcoming sessions'),
        ...upcoming.map(
          (booking) => BookingTile(booking: booking, showPaymentStatus: true),
        ),
        const SectionHeader(title: 'Member feedback'),
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.rate_review_outlined),
            title: const Text('Share your gym feedback'),
            subtitle: const Text(
              'Rate trainers, equipment, and your session experience.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onFeedback,
          ),
        ),
        const SectionHeader(title: 'Recent notifications'),
        ...repo.notifications
            .take(3)
            .map(
              (item) => AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(item.type.icon),
                  title: Text(item.title),
                  subtitle: Text(item.message),
                  trailing: item.isRead
                      ? null
                      : const StatusBadge(label: 'Pending', compact: true),
                ),
              ),
            ),
      ],
    );
  }

  void _handleQuickBook(BuildContext context, AppState state) {
    if (state.hasBookableMembership) {
      onQuickBook?.call();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Renew or select a membership plan before booking.'),
      ),
    );
    onRenew?.call();
  }

  Future<void> _exportMembership(BuildContext context, String format, MembershipRecord? membership) async {
    if (membership == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No membership selected to export.')),
      );
      return;
    }

    final uri = Uri.parse('http://localhost:8000/api/exports/membership/?format=${format.toLowerCase()}');
    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 15));
      if (resp.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: ${resp.body}')));
        return;
      }
      final docsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${docsDir.path}/reports');
      if (!await exportDir.exists()) await exportDir.create(recursive: true);
      final extension = resp.headers['content-type']?.contains('pdf') == true ? 'pdf' : 'xlsx';
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
      final fileName = 'membership_$timestamp.$extension';
      final file = File('${exportDir.path}/$fileName');
      await file.writeAsBytes(resp.bodyBytes);
      if (!context.mounted) return;
      await OpenFile.open(file.path);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$format export saved to ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }
}
