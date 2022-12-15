import 'package:flutter/material.dart';

/// A adaptive circular progress indicator which size is constrained so it can fit
/// in buttons.
class ButtonLoadingIndicator extends StatelessWidget {
  const ButtonLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
        ));
  }
}
