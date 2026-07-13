import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers_or_bloc/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: GymBookingApp()));
}

class GymBookingApp extends ConsumerWidget {
  const GymBookingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final router = ref.watch(appRouterProvider);

    return AppScope(
      state: appState,
      child: MaterialApp.router(
        title: 'FitFlow Elite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: appState.themeMode,
        routerConfig: router,
      ),
    );
  }
}
