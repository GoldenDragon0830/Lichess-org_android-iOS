import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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

/// A centered circular progress indicator
class CenterLoadingIndicator extends StatelessWidget {
  const CenterLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator.adaptive(),
    );
  }
}

// TODO animation
void showCupertinoErrorSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(milliseconds: 5000),
}) {
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      // default iOS tab bar height + 10
      bottom: 60.0,
      left: 8.0,
      right: 8.0,
      child: SafeArea(
        child: CupertinoPopupSurface(
          isSurfacePainted: true,
          child: Container(
            color: CupertinoColors.systemRed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: CupertinoColors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Future.delayed(
    duration,
    overlayEntry.remove,
  );
  Overlay.of(Navigator.of(context).context)?.insert(overlayEntry);
}
