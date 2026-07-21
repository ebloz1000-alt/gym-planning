import 'package:flutter/material.dart';
import 'dart:js' as js;

class InstallButton extends StatelessWidget {
  const InstallButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        try {
          js.context.callMethod('triggerInstall');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Install not available')),
          );
        }
      },
      label: const Text('Install App'),
      icon: const Icon(Icons.download),
    );
  }
}
