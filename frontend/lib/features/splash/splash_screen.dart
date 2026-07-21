import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/state_views.dart';
import '../../providers_or_bloc/app_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.fitness_center_outlined,
                          color: scheme.onPrimaryContainer,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Equipment and trainer booking for members, trainers, and admins.',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _SplashCheck(
                        icon: Icons.wifi_tethering_outlined,
                        label: 'Internet connection',
                        value: state.hasInternet ? 'Connected' : 'Offline',
                      ),
                      _SplashCheck(
                        icon: Icons.verified_outlined,
                        label: 'App version',
                        value: state.appVersionStatus,
                      ),
                      _SplashCheck(
                        icon: Icons.key_outlined,
                        label: 'JWT validation',
                        value: state.jwtStatus,
                      ),
                      _SplashCheck(
                        icon: Icons.manage_accounts_outlined,
                        label: 'Role detection',
                        value: state.currentRole?.label ?? 'Waiting for login',
                      ),
                      const SizedBox(height: 24),
                      const LoadingStateView(message: 'Preparing your workspace'),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Version ${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplashCheck extends StatelessWidget {
  const _SplashCheck({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}
