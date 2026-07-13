import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/app_cards.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationType? _filter;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final role = state.currentRole;
    final availableTypes = _availableTypesFor(role);
    final effectiveFilter = availableTypes.contains(_filter) ? _filter : null;
    final notifications = state.repository.notifications.where((item) {
      return availableTypes.contains(item.type) &&
          (effectiveFilter == null || item.type == effectiveFilter);
    }).toList();
    return FeaturePage(
      title: role == UserRole.trainer
          ? 'Trainer Notifications'
          : 'Notifications',
      subtitle: _subtitleFor(role),
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            role == UserRole.trainer ? 'Trainer alerts' : 'Push notifications',
          ),
          subtitle: Text(_toggleCopyFor(role)),
          value: state.notificationsEnabled,
          onChanged: state.setNotificationsEnabled,
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: effectiveFilter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              ...availableTypes.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(type.icon, size: 18),
                    label: Text(type.label),
                    selected: effectiveFilter == type,
                    onSelected: (_) => setState(() => _filter = type),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'Notification center'),
        if (notifications.isEmpty)
          const AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.notifications_off_outlined),
              title: Text('No notifications for this role'),
              subtitle: Text('New alerts will appear here when they arrive.'),
            ),
          ),
        ...notifications.map(
          (item) => Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.mark_email_read_outlined),
            ),
            onDismissed: (_) => state.markNotificationRead(item.id),
            child: AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.type.icon),
                title: Text(item.title),
                subtitle: Text(
                  '${item.message}\n${formatDate(item.createdAt)}',
                ),
                isThreeLine: true,
                trailing: item.isRead
                    ? const StatusBadge(label: 'Read', compact: true)
                    : const StatusBadge(label: 'Pending', compact: true),
                onTap: () => state.markNotificationRead(item.id),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<NotificationType> _availableTypesFor(UserRole? role) {
    if (role == UserRole.trainer) {
      return const [
        NotificationType.booking,
        NotificationType.trainer,
        NotificationType.reminder,
      ];
    }
    return NotificationType.values;
  }

  String _subtitleFor(UserRole? role) {
    if (role == UserRole.trainer) {
      return 'Session changes, availability updates, member feedback, and reminders.';
    }
    return 'Firebase-ready categorized notification center and settings.';
  }

  String _toggleCopyFor(UserRole? role) {
    if (role == UserRole.trainer) {
      return 'Booking assignments, schedule changes, feedback, and reminders';
    }
    return 'Booking, membership, payment, trainer, and reminders';
  }
}
