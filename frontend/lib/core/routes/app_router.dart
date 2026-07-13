import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_dashboard.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/booking/booking_screen.dart';
import '../../features/feedback/feedback_screen.dart';
import '../../features/help/help_screen.dart';
import '../../features/member/member_dashboard.dart';
import '../../features/membership/membership_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/payments/payment_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/trainer/trainer_screen.dart';
import '../../models/app_models.dart';
import '../../providers_or_bloc/app_state.dart';
import '../constants/app_constants.dart';
import '../widgets/app_cards.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final appState = ref.read(appStateProvider);
  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: appState,
    redirect: (_, state) => _redirectFor(appState, state),
    routes: [
      GoRoute(
        path: '/',
        name: 'root',
        pageBuilder: (context, state) =>
            _premiumPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) =>
            _premiumPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) =>
            _premiumPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) =>
            _premiumPage(state, const AuthScreen()),
      ),
      GoRoute(
        path: '/app',
        name: 'app',
        pageBuilder: (context, state) {
          final appState = AppScope.watch(context);
          return _premiumPage(
            state,
            RoleShell(role: appState.currentRole ?? UserRole.member),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'We could not open that page.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    ),
  );

  ref.onDispose(router.dispose);
  return router;
});

String? _redirectFor(AppState appState, GoRouterState state) {
  final target = _targetPath(appState);
  final current = state.uri.path;
  if (current == target) return null;
  return target;
}

String _targetPath(AppState state) {
  if (!state.isBootstrapped) return '/splash';
  if (!state.hasCompletedOnboarding) return '/onboarding';
  if (state.currentRole == null) return '/auth';
  return '/app';
}

Page<void> _premiumPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.role});

  final UserRole role;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _primaryIndex = 0;
  int? _drawerIndex;

  @override
  void didUpdateWidget(covariant RoleShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      _primaryIndex = 0;
      _drawerIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final config = _navigationFor(widget.role);
    final primaryDestinations = config.primaryDestinations;
    final drawerDestinations = config.drawerDestinations;
    if (_primaryIndex >= primaryDestinations.length) _primaryIndex = 0;
    if (_drawerIndex != null && _drawerIndex! >= drawerDestinations.length) {
      _drawerIndex = null;
    }

    final selected = _drawerIndex == null
        ? primaryDestinations[_primaryIndex]
        : drawerDestinations[_drawerIndex!];
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('${AppConstants.appName} - ${widget.role.label}'),
        actions: [
          IconButton(
            tooltip: 'Refresh session',
            onPressed: state.refreshJwt,
            icon: const Icon(Icons.sync_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: state.logout,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      drawer: _RoleDrawer(
        selectedIndex: _drawerIndex,
        destinations: drawerDestinations,
        onSelected: (value) {
          setState(() => _drawerIndex = value);
          Navigator.of(context).maybePop();
        },
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _drawerIndex == null ? _primaryIndex : null,
                  extended: MediaQuery.sizeOf(context).width >= 1120,
                  scrollable: true,
                  labelType: MediaQuery.sizeOf(context).width >= 1120
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: _selectPrimaryDestination,
                  destinations: primaryDestinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon ?? item.icon),
                          label: Text(item.title),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: selected.builder(context)),
              ],
            )
          : selected.builder(context),
      bottomNavigationBar: isWide
          ? null
          : _BottomRoleNavigation(
              destinations: primaryDestinations,
              selectedIndex: _primaryIndex,
              onSelected: _selectPrimaryDestination,
            ),
    );
  }

  void _selectPrimaryDestination(int value) {
    if (widget.role == UserRole.member &&
        value == 1 &&
        !AppScope.read(context).hasBookableMembership) {
      _openMembership(showMessage: true);
      return;
    }
    setState(() {
      _primaryIndex = value;
      _drawerIndex = null;
    });
  }

  void _openMembership({bool showMessage = false}) {
    _openDrawerDestination(0);
    if (!showMessage) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select or renew a membership plan before booking.'),
      ),
    );
  }

  void _openDrawerDestination(int index) {
    setState(() {
      _primaryIndex = 0;
      _drawerIndex = index;
    });
  }

  _RoleNavigationConfig _navigationFor(UserRole role) {
    switch (role) {
      case UserRole.member:
        return _RoleNavigationConfig(
          primaryDestinations: [
            RoleDestination(
              'Dashboard',
              Icons.home_outlined,
              MemberDashboard(
                onQuickBook: () => _selectPrimaryDestination(1),
                onRenew: () => _openMembership(),
                onFeedback: () => _openDrawerDestination(1),
              ),
              selectedIcon: Icons.home_rounded,
            ),
            RoleDestination(
              'Book Session',
              Icons.event_available_outlined,
              BookingScreen(onOpenMembership: () => _openMembership()),
              selectedIcon: Icons.event_available_rounded,
            ),
            RoleDestination(
              'My Bookings',
              Icons.list_alt_outlined,
              MyBookingsScreen(),
              selectedIcon: Icons.list_alt_rounded,
            ),
            RoleDestination(
              'Notifications',
              Icons.notifications_none_outlined,
              NotificationsScreen(),
              selectedIcon: Icons.notifications_rounded,
            ),
            RoleDestination(
              'Profile',
              Icons.person_outline,
              ProfileScreen(),
              selectedIcon: Icons.person_rounded,
            ),
          ],
          drawerDestinations: [
            RoleDestination(
              'Membership',
              Icons.workspace_premium_outlined,
              MembershipScreen(),
            ),
            RoleDestination(
              'Feedback',
              Icons.rate_review_outlined,
              FeedbackScreen(),
            ),
            RoleDestination(
              'Settings',
              Icons.settings_outlined,
              SettingsScreen(),
            ),
            RoleDestination('Help', Icons.help_outline, HelpScreen()),
          ],
        );
      case UserRole.trainer:
        return const _RoleNavigationConfig(
          primaryDestinations: [
            RoleDestination(
              'Dashboard',
              Icons.dashboard_outlined,
              TrainerModuleScreen(),
              selectedIcon: Icons.dashboard_rounded,
            ),
            RoleDestination(
              'My Sessions',
              Icons.event_note_outlined,
              TrainerSessionsScreen(),
              selectedIcon: Icons.event_note_rounded,
            ),
            RoleDestination(
              'Schedule',
              Icons.calendar_month_outlined,
              TrainerScheduleScreen(),
              selectedIcon: Icons.calendar_month_rounded,
            ),
            RoleDestination(
              'Notifications',
              Icons.notifications_none_outlined,
              NotificationsScreen(),
              selectedIcon: Icons.notifications_rounded,
            ),
            RoleDestination(
              'Profile',
              Icons.person_outline,
              ProfileScreen(),
              selectedIcon: Icons.person_rounded,
            ),
          ],
          drawerDestinations: [
            RoleDestination(
              'Feedback',
              Icons.rate_review_outlined,
              FeedbackScreen(),
            ),
            RoleDestination(
              'Settings',
              Icons.settings_outlined,
              SettingsScreen(),
            ),
            RoleDestination('Help', Icons.help_outline, HelpScreen()),
          ],
        );
      case UserRole.admin:
        return const _RoleNavigationConfig(
          primaryDestinations: [
            RoleDestination(
              'Dashboard',
              Icons.dashboard_outlined,
              AdminDashboard(),
              selectedIcon: Icons.dashboard_rounded,
            ),
            RoleDestination(
              'Users',
              Icons.groups_outlined,
              UserManagementScreen(),
              selectedIcon: Icons.groups_rounded,
            ),
            RoleDestination(
              'Bookings',
              Icons.event_note_outlined,
              AdminBookingManagementScreen(),
              selectedIcon: Icons.event_note_rounded,
            ),
            RoleDestination(
              'Reports',
              Icons.summarize_outlined,
              ReportsScreen(),
              selectedIcon: Icons.summarize_rounded,
            ),
            RoleDestination(
              'Notifications',
              Icons.notifications_none_outlined,
              NotificationsScreen(),
              selectedIcon: Icons.notifications_rounded,
            ),
          ],
          drawerDestinations: [
            RoleDestination(
              'Equipment',
              Icons.inventory_2_outlined,
              AdminEquipmentManagementScreen(),
            ),
            RoleDestination(
              'Analytics',
              Icons.insights_outlined,
              AnalyticsScreen(),
            ),
            RoleDestination(
              'Payments',
              Icons.payments_outlined,
              PaymentScreen(),
            ),
            RoleDestination('Profile', Icons.person_outline, ProfileScreen()),
            RoleDestination(
              'Settings',
              Icons.settings_outlined,
              SettingsScreen(),
            ),
            RoleDestination('Help', Icons.help_outline, HelpScreen()),
          ],
        );
    }
  }
}

class _RoleNavigationConfig {
  const _RoleNavigationConfig({
    required this.primaryDestinations,
    required this.drawerDestinations,
  });

  final List<RoleDestination> primaryDestinations;
  final List<RoleDestination> drawerDestinations;
}

class RoleDestination {
  const RoleDestination(this.title, this.icon, this.page, {this.selectedIcon});

  final String title;
  final IconData icon;
  final IconData? selectedIcon;
  final Widget page;

  WidgetBuilder get builder =>
      (_) => page;
}

class _RoleDrawer extends StatelessWidget {
  const _RoleDrawer({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int? selectedIndex;
  final List<RoleDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final user = state.currentUser;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  AppAvatar(label: user?.avatarLabel ?? 'FF'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? AppConstants.appName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(user?.role.label ?? 'Guest'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (var i = 0; i < destinations.length; i++)
              NavigationDrawerDestination(
                icon: Icon(destinations[i].icon),
                selectedIcon: Icon(
                  destinations[i].selectedIcon ?? destinations[i].icon,
                ),
                label: Text(destinations[i].title),
              ).asListTile(
                context: context,
                selected: selectedIndex == i,
                onTap: () => onSelected(i),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: const Text('Logout'),
              onTap: state.logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomRoleNavigation extends StatelessWidget {
  const _BottomRoleNavigation({
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<RoleDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: destinations
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon ?? item.icon),
              label: item.title,
            ),
          )
          .toList(),
    );
  }
}

extension on NavigationDrawerDestination {
  Widget asListTile({
    required BuildContext context,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      selected: selected,
      leading: selected ? selectedIcon : icon,
      title: label,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
