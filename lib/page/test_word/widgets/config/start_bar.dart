import 'package:flutter/material.dart';

import '../ui_test_components.dart';

/// The start button, pinned to the bottom of the config screen.
class StartBar extends StatelessWidget {
  const StartBar({
    super.key,
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TestScreenBottomBar(
      child: TestScreenPrimaryButton(
        label: label,
        icon: Icons.arrow_forward_rounded,
        loading: loading,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
