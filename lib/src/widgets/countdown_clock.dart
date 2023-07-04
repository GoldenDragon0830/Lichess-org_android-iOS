import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lichess_mobile/src/model/settings/brightness.dart';
import 'package:lichess_mobile/src/model/common/service/sound_service.dart';
import 'package:lichess_mobile/src/constants.dart';

/// A simple countdown clock.
///
/// The clock starts only when [active] is `true`.
class CountdownClock extends ConsumerStatefulWidget {
  final Duration duration;
  final Duration? emergencyThreshold;
  final bool active;

  const CountdownClock({
    required this.duration,
    required this.active,
    this.emergencyThreshold,
    super.key,
  });

  @override
  ConsumerState<CountdownClock> createState() => _CountdownClockState();
}

const _period = Duration(milliseconds: 100);
const _emergencyDelay = Duration(seconds: 20);

class _CountdownClockState extends ConsumerState<CountdownClock> {
  Timer? _timer;
  Duration timeLeft = Duration.zero;
  DateTime _lastUpdate = DateTime.now();
  DateTime? _nextEmergency;

  Timer startTimer() {
    _timer?.cancel();
    _lastUpdate = DateTime.now();
    return Timer.periodic(_period, (timer) {
      setState(() {
        final now = DateTime.now();
        timeLeft = timeLeft - now.difference(_lastUpdate);
        _lastUpdate = now;
        final isEmergency = widget.emergencyThreshold != null &&
            timeLeft <= widget.emergencyThreshold!;
        _playEmergencyFeedback(isEmergency);
        if (timeLeft <= Duration.zero) {
          timeLeft = Duration.zero;
          timer.cancel();
        }
      });
    });
  }

  void _playEmergencyFeedback(bool isEmergency) {
    if (isEmergency &&
        (_nextEmergency == null || _nextEmergency!.isBefore(DateTime.now()))) {
      _nextEmergency = DateTime.now().add(_emergencyDelay);
      ref.read(soundServiceProvider).play(Sound.lowTime);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void initState() {
    super.initState();
    timeLeft = widget.duration;
    if (widget.active) {
      _timer = startTimer();
    }
  }

  @override
  void didUpdateWidget(CountdownClock oldClock) {
    super.didUpdateWidget(oldClock);
    if (widget.duration != oldClock.duration) {
      timeLeft = widget.duration;
    }
    if (widget.active) {
      _timer = startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final min = timeLeft.inMinutes.remainder(60);
    final secs = timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = timeLeft.inMilliseconds.remainder(1000) ~/ 100;
    final showTenths = timeLeft < const Duration(seconds: 10);
    final isEmergency = widget.emergencyThreshold != null &&
        timeLeft <= widget.emergencyThreshold!;
    final brightness = ref.watch(currentBrightnessProvider);
    final clockStyle = brightness == Brightness.dark
        ? ClockStyle.darkThemeStyle
        : ClockStyle.lightThemeStyle;
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final screenHeight = mediaQueryData.size.height;

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        color: widget.active
            ? isEmergency
                ? clockStyle.emergencyBackgroundColor
                : clockStyle.activeBackgroundColor
            : clockStyle.backgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 5.0),
        child: MediaQuery(
          data: mediaQueryData.copyWith(
            textScaleFactor: math.min(
              mediaQueryData.textScaleFactor,
              kMaxClockTextScaleFactor,
            ),
          ),
          child: RichText(
            text: TextSpan(
              text: '$min:$secs',
              style: TextStyle(
                color: widget.active
                    ? isEmergency
                        ? clockStyle.emergencyTextColor
                        : clockStyle.activeTextColor
                    : clockStyle.textColor,
                fontSize: screenHeight < kSmallHeightScreenThreshold ? 20 : 24,
                height: screenHeight < kSmallHeightScreenThreshold ? 1.0 : null,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
              children: [
                if (showTenths)
                  TextSpan(
                    text: '.$tenths',
                    style: TextStyle(
                      fontSize:
                          screenHeight < kSmallHeightScreenThreshold ? 14 : 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@immutable
class ClockStyle {
  const ClockStyle({
    required this.textColor,
    required this.activeTextColor,
    required this.emergencyTextColor,
    required this.backgroundColor,
    required this.activeBackgroundColor,
    required this.emergencyBackgroundColor,
  });

  static const darkThemeStyle = ClockStyle(
    textColor: Colors.grey,
    activeTextColor: Colors.black,
    emergencyTextColor: Colors.white,
    backgroundColor: Colors.black,
    activeBackgroundColor: Color(0xFFDDDDDD),
    emergencyBackgroundColor: Color(0xFF673431),
  );

  static const lightThemeStyle = ClockStyle(
    textColor: Colors.grey,
    activeTextColor: Colors.black,
    emergencyTextColor: Colors.black,
    backgroundColor: Colors.white,
    activeBackgroundColor: Color(0xFFD0E0BD),
    emergencyBackgroundColor: Color(0xFFF2CCCC),
  );

  final Color textColor;
  final Color activeTextColor;
  final Color emergencyTextColor;
  final Color backgroundColor;
  final Color activeBackgroundColor;
  final Color emergencyBackgroundColor;
}
