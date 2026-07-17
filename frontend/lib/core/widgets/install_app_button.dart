import 'package:flutter/material.dart';

import '../../providers_or_bloc/app_state.dart';

class InstallAppButton extends StatelessWidget {
  const InstallAppButton({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.watch(context);
    return IconButton.filledTonal(
      tooltip: 'Install App',
      icon: const Icon(Icons.download_rounded),
      onPressed: state.pwaManager.available
          ? () async {
              await state.pwaManager.promptInstall();
            }
          : null,
    );
  }
}
