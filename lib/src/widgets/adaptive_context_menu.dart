import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

// copied and modified from original flutter [CupertinoContextMenu] widget
// https://github.com/flutter/flutter/blob/stable/packages/flutter/lib/src/cupertino/context_menu.dart

// The scale of the child at the time that the LichessCupertinoContextMenu opens.
const double _kOpenScale = 1.03;

// The ratio for the borderRadius of the context menu preview image. This value
// was eyeballed by overlapping the LichessCupertinoContextMenu with a context menu
// from iOS 16.0 in the XCode iPhone simulator.
const double _previewBorderRadiusRatio = 12.0;

// The duration of the transition used when a modal popup is shown. Eyeballed
// from a physical device running iOS 13.1.2.
const Duration _kModalPopupTransitionDuration = Duration(milliseconds: 335);

// The duration it takes for the LichessCupertinoContextMenu to open.
// This value was eyeballed from the XCode simulator running iOS 16.0.
const Duration _previewLongPressTimeout = Duration(milliseconds: 800);

// The total length of the combined animations until the menu is fully open.
final int _animationDuration = _previewLongPressTimeout.inMilliseconds +
    _kModalPopupTransitionDuration.inMilliseconds;

// The final box shadow for the opening child widget.
// This value was eyeballed from the XCode simulator running iOS 16.0.
const List<BoxShadow> _endBoxShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x40000000),
    blurRadius: 10.0,
    spreadRadius: 0.5,
  ),
];

const Color _borderColor = CupertinoDynamicColor.withBrightness(
  color: Color(0xFFA9A9AF),
  darkColor: Color(0xFF57585A),
);

// ignore: avoid_private_typedef_functions
typedef _DismissCallback = void Function(
  BuildContext context,
  double scale,
  double opacity,
);

/// A function that produces the preview when the LichessCupertinoContextMenu is open.
///
/// Called every time the animation value changes.
typedef ContextMenuPreviewBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Widget child,
);

/// A function that builds the child and handles the transition between the
/// default child and the preview when the LichessCupertinoContextMenu is open.
typedef CupertinoContextMenuBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
);

// Given a GlobalKey, return the Rect of the corresponding RenderBox's
// paintBounds in global coordinates.
Rect _getRect(GlobalKey globalKey) {
  assert(globalKey.currentContext != null);
  final RenderBox renderBoxContainer =
      globalKey.currentContext!.findRenderObject()! as RenderBox;
  return Rect.fromPoints(
    renderBoxContainer.localToGlobal(
      renderBoxContainer.paintBounds.topLeft,
    ),
    renderBoxContainer
        .localToGlobal(renderBoxContainer.paintBounds.bottomRight),
  );
}

// The context menu arranges itself slightly differently based on the location
// on the screen of [LichessCupertinoContextMenu.child] before the
// [LichessCupertinoContextMenu] opens.
enum _ContextMenuLocation {
  center,
  left,
  right,
}

class AdaptiveContextMenuAction extends StatelessWidget {
  const AdaptiveContextMenuAction({
    required this.child,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    this.icon,
    this.onPressed,
    this.closeOnPressed = true,
  });

  final IconData? icon;
  final VoidCallback? onPressed;
  final Widget child;
  final bool isDefaultAction;
  final bool isDestructiveAction;
  final bool closeOnPressed;

  @override
  Widget build(BuildContext context) {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? CupertinoContextMenuAction(
            isDefaultAction: isDefaultAction,
            isDestructiveAction: isDestructiveAction,
            trailingIcon: icon,
            onPressed: () {
              if (closeOnPressed) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              onPressed?.call();
            },
            child: child,
          )
        : ListTile(
            leading: Icon(icon),
            title: child,
            onTap: () {
              if (closeOnPressed) {
                Navigator.of(context, rootNavigator: true).pop();
              }
              onPressed?.call();
            },
          );
  }
}

class LichessCupertinoContextMenu extends StatefulWidget {
  LichessCupertinoContextMenu.builder({
    super.key,
    required this.actions,
    required this.builder,
    this.enableHapticFeedback = false,
  }) : assert(actions.isNotEmpty);

  static const double kOpenBorderRadius = _previewBorderRadiusRatio;

  static const List<BoxShadow> kEndBoxShadow = _endBoxShadow;

  static final double animationOpensAt =
      _previewLongPressTimeout.inMilliseconds / _animationDuration;

  final CupertinoContextMenuBuilder builder;

  final List<Widget> actions;

  final bool enableHapticFeedback;

  @override
  State<LichessCupertinoContextMenu> createState() =>
      _CupertinoContextMenuState();
}

class _CupertinoContextMenuState extends State<LichessCupertinoContextMenu>
    with TickerProviderStateMixin {
  final GlobalKey _childGlobalKey = GlobalKey();
  bool _childHidden = false;
  // Animates the child while it's opening.
  late AnimationController _openController;
  Rect? _decoyChildEndRect;
  OverlayEntry? _lastOverlayEntry;
  _ContextMenuRoute<void>? _route;
  final double _midpoint = LichessCupertinoContextMenu.animationOpensAt / 2;
  late final TapGestureRecognizer _tapGestureRecognizer;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      duration: _previewLongPressTimeout,
      vsync: this,
      upperBound: LichessCupertinoContextMenu.animationOpensAt,
    );
    _openController.addStatusListener(_onDecoyAnimationStatusChange);
    _tapGestureRecognizer = TapGestureRecognizer()
      ..onTapCancel = _onTapCancel
      ..onTapDown = _onTapDown
      ..onTapUp = _onTapUp
      ..onTap = _onTap;
  }

  void _listenerCallback() {
    if (_openController.status != AnimationStatus.reverse &&
        _openController.value >= _midpoint) {
      if (widget.enableHapticFeedback) {
        HapticFeedback.heavyImpact();
      }
      _tapGestureRecognizer.resolve(GestureDisposition.accepted);
      _openController.removeListener(_listenerCallback);
    }
  }

  // Determine the _ContextMenuLocation based on the location of the original
  // child in the screen.
  //
  // The location of the original child is used to determine how to horizontally
  // align the content of the open LichessCupertinoContextMenu. For example, if the
  // child is near the center of the screen, it will also appear in the center
  // of the screen when the menu is open, and the actions will be centered below
  // it.
  _ContextMenuLocation get _contextMenuLocation {
    final Rect childRect = _getRect(_childGlobalKey);
    final double screenWidth = MediaQuery.sizeOf(context).width;

    final double center = screenWidth / 2;
    final bool centerDividesChild =
        childRect.left < center && childRect.right > center;
    final double distanceFromCenter = (center - childRect.center.dx).abs();
    if (centerDividesChild && distanceFromCenter <= childRect.width / 4) {
      return _ContextMenuLocation.center;
    }

    if (childRect.center.dx > center) {
      return _ContextMenuLocation.right;
    }

    return _ContextMenuLocation.left;
  }

  // Push the new route and open the LichessCupertinoContextMenu overlay.
  void _openContextMenu() {
    setState(() {
      _childHidden = true;
    });

    _route = _ContextMenuRoute<void>(
      actions: widget.actions,
      barrierLabel: CupertinoLocalizations.of(context).menuDismissLabel,
      filter: ui.ImageFilter.blur(
        sigmaX: 5.0,
        sigmaY: 5.0,
      ),
      contextMenuLocation: _contextMenuLocation,
      previousChildRect: _decoyChildEndRect!,
      builder: (BuildContext context, Animation<double> animation) {
        final Animation<double> localAnimation = Tween<double>(
          begin: LichessCupertinoContextMenu.animationOpensAt,
          end: 1,
        ).animate(animation);
        return widget.builder(context, localAnimation);
      },
    );
    Navigator.of(context, rootNavigator: true).push<void>(_route!);
    _route!.animation!.addStatusListener(_routeAnimationStatusListener);
  }

  void _onDecoyAnimationStatusChange(AnimationStatus animationStatus) {
    switch (animationStatus) {
      case AnimationStatus.dismissed:
        if (_route == null) {
          setState(() {
            _childHidden = false;
          });
        }
        _lastOverlayEntry?.remove();
        _lastOverlayEntry?.dispose();
        _lastOverlayEntry = null;

      case AnimationStatus.completed:
        setState(() {
          _childHidden = true;
        });
        _openContextMenu();
        // Keep the decoy on the screen for one extra frame. We have to do this
        // because _ContextMenuRoute renders its first frame offscreen.
        // Otherwise there would be a visible flash when nothing is rendered for
        // one frame.
        SchedulerBinding.instance.addPostFrameCallback((Duration _) {
          _lastOverlayEntry?.remove();
          _lastOverlayEntry?.dispose();
          _lastOverlayEntry = null;
          _openController.reset();
        });

      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        return;
    }
  }

  // Watch for when _ContextMenuRoute is closed and return to the state where
  // the LichessCupertinoContextMenu just behaves as a Container.
  void _routeAnimationStatusListener(AnimationStatus status) {
    if (status != AnimationStatus.dismissed) {
      return;
    }
    if (mounted) {
      setState(() {
        _childHidden = false;
      });
    }
    _route!.animation!.removeStatusListener(_routeAnimationStatusListener);
    _route = null;
  }

  void _onTap() {
    _openController.removeListener(_listenerCallback);
    if (_openController.isAnimating && _openController.value < _midpoint) {
      _openController.reverse();
    }
  }

  void _onTapCancel() {
    _openController.removeListener(_listenerCallback);
    if (_openController.isAnimating && _openController.value < _midpoint) {
      _openController.reverse();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _openController.removeListener(_listenerCallback);
    if (_openController.isAnimating && _openController.value < _midpoint) {
      _openController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    _openController.addListener(_listenerCallback);
    setState(() {
      _childHidden = true;
    });

    final Rect childRect = _getRect(_childGlobalKey);
    _decoyChildEndRect = Rect.fromCenter(
      center: childRect.center,
      width: childRect.width * _kOpenScale,
      height: childRect.height * _kOpenScale,
    );

    // Create a decoy child in an overlay directly on top of the original child.
    // TODO(justinmc): There is a known inconsistency with native here, due to
    // doing the bounce animation using a decoy in the top level Overlay. The
    // decoy will pop on top of the AppBar if the child is partially behind it,
    // such as a top item in a partially scrolled view. However, if we don't use
    // an overlay, then the decoy will appear behind its neighboring widget when
    // it expands. This may be solvable by adding a widget to Scaffold that's
    // underneath the AppBar.
    _lastOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return _DecoyChild(
          beginRect: childRect,
          controller: _openController,
          endRect: _decoyChildEndRect,
          builder: widget.builder,
        );
      },
    );
    Overlay.of(context, rootOverlay: true, debugRequiredFor: widget)
        .insert(_lastOverlayEntry!);
    _openController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
      child: Listener(
        onPointerDown: _tapGestureRecognizer.addPointer,
        child: TickerMode(
          enabled: !_childHidden,
          child: Visibility.maintain(
            key: _childGlobalKey,
            visible: !_childHidden,
            child: widget.builder(context, _openController),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _openController.dispose();
    super.dispose();
  }
}

// A floating copy of the LichessCupertinoContextMenu's child.
//
// When the child is pressed, but before the LichessCupertinoContextMenu opens, it does
// an animation where it slowly grows. This is implemented by hiding the
// original child and placing _DecoyChild on top of it in an Overlay. The use of
// an Overlay allows the _DecoyChild to appear on top of siblings of the
// original child.
class _DecoyChild extends StatefulWidget {
  const _DecoyChild({
    this.beginRect,
    required this.controller,
    this.endRect,
    this.builder,
  });

  final Rect? beginRect;
  final AnimationController controller;
  final Rect? endRect;
  final CupertinoContextMenuBuilder? builder;

  @override
  _DecoyChildState createState() => _DecoyChildState();
}

class _DecoyChildState extends State<_DecoyChild>
    with TickerProviderStateMixin {
  late Animation<Rect?> _rect;

  @override
  void initState() {
    super.initState();

    const double beginPause = 1.0;
    const double openAnimationLength = 5.0;
    const double totalOpenAnimationLength = beginPause + openAnimationLength;
    final double endPause = ((totalOpenAnimationLength * _animationDuration) /
            _previewLongPressTimeout.inMilliseconds) -
        totalOpenAnimationLength;

    // The timing on the animation was eyeballed from the XCode iOS simulator
    // running iOS 16.0.
    // Because the animation no longer goes from 0.0 to 1.0, but to a number
    // depending on the ratio between the press animation time and the opening
    // animation time, a pause needs to be added to the end of the tween
    // sequence that completes that ratio. This is to allow the animation to
    // fully complete as expected without doing crazy math to the _kOpenScale
    // value. This change was necessary from the inclusion of the builder and
    // the complete animation value that it passes along.
    _rect = TweenSequence<Rect?>(<TweenSequenceItem<Rect?>>[
      TweenSequenceItem<Rect?>(
        tween: RectTween(
          begin: widget.beginRect,
          end: widget.beginRect,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: beginPause,
      ),
      TweenSequenceItem<Rect?>(
        tween: RectTween(
          begin: widget.beginRect,
          end: widget.endRect,
        ).chain(CurveTween(curve: Curves.easeOutSine)),
        weight: openAnimationLength,
      ),
      TweenSequenceItem<Rect?>(
        tween: RectTween(
          begin: widget.endRect,
          end: widget.endRect,
        ).chain(CurveTween(curve: Curves.linear)),
        weight: endPause,
      ),
    ]).animate(widget.controller);
  }

  Widget _buildBuilder(BuildContext context, Widget? child) {
    return Positioned.fromRect(
      rect: _rect.value!,
      child: widget.builder!(context, widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          builder: _buildBuilder,
          animation: widget.controller,
        ),
      ],
    );
  }
}

// The open LichessCupertinoContextMenu modal.
class _ContextMenuRoute<T> extends PopupRoute<T> {
  // Build a _ContextMenuRoute.
  _ContextMenuRoute({
    required List<Widget> actions,
    required _ContextMenuLocation contextMenuLocation,
    this.barrierLabel,
    CupertinoContextMenuBuilder? builder,
    super.filter,
    required Rect previousChildRect,
    super.settings,
  })  : assert(actions.isNotEmpty),
        _actions = actions,
        _builder = builder,
        _contextMenuLocation = contextMenuLocation,
        _previousChildRect = previousChildRect;

  // Barrier color for a Cupertino modal barrier.
  static const Color _kModalBarrierColor = Color(0x6604040F);

  final List<Widget> _actions;
  final CupertinoContextMenuBuilder? _builder;
  final GlobalKey _childGlobalKey = GlobalKey();
  final _ContextMenuLocation _contextMenuLocation;
  bool _externalOffstage = false;
  bool _internalOffstage = false;
  Orientation? _lastOrientation;
  // The Rect of the child at the moment that the LichessCupertinoContextMenu opens.
  final Rect _previousChildRect;
  double? _scale = 1.0;
  final GlobalKey _sheetGlobalKey = GlobalKey();

  static final CurveTween _curve = CurveTween(
    curve: Curves.easeOutBack,
  );
  static final CurveTween _curveReverse = CurveTween(
    curve: Curves.easeInBack,
  );
  static final RectTween _rectTween = RectTween();
  static final Animatable<Rect?> _rectAnimatable = _rectTween.chain(_curve);
  static final RectTween _rectTweenReverse = RectTween();
  static final Animatable<Rect?> _rectAnimatableReverse =
      _rectTweenReverse.chain(
    _curveReverse,
  );
  static final RectTween _sheetRectTween = RectTween();
  final Animatable<Rect?> _sheetRectAnimatable = _sheetRectTween.chain(
    _curve,
  );
  final Animatable<Rect?> _sheetRectAnimatableReverse = _sheetRectTween.chain(
    _curveReverse,
  );
  static final Tween<double> _sheetScaleTween = Tween<double>();
  static final Animatable<double> _sheetScaleAnimatable =
      _sheetScaleTween.chain(
    _curve,
  );
  static final Animatable<double> _sheetScaleAnimatableReverse =
      _sheetScaleTween.chain(
    _curveReverse,
  );
  final Tween<double> _opacityTween = Tween<double>(begin: 0.0, end: 1.0);
  late Animation<double> _sheetOpacity;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => _kModalBarrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  bool get semanticsDismissible => false;

  @override
  Duration get transitionDuration => _kModalPopupTransitionDuration;

  // Getting the RenderBox doesn't include the scale from the Transform.scale,
  // so it's manually accounted for here.
  static Rect _getScaledRect(GlobalKey globalKey, double scale) {
    final Rect childRect = _getRect(globalKey);
    final Size sizeScaled = childRect.size * scale;
    final Offset offsetScaled = Offset(
      childRect.left + (childRect.size.width - sizeScaled.width) / 2,
      childRect.top + (childRect.size.height - sizeScaled.height) / 2,
    );
    return offsetScaled & sizeScaled;
  }

  // Get the alignment for the _ContextMenuSheet's Transform.scale based on the
  // contextMenuLocation.
  static AlignmentDirectional getSheetAlignment(
    _ContextMenuLocation contextMenuLocation,
  ) {
    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        return AlignmentDirectional.topCenter;
      case _ContextMenuLocation.right:
        return AlignmentDirectional.topEnd;
      case _ContextMenuLocation.left:
        return AlignmentDirectional.topStart;
    }
  }

  // The place to start the sheetRect animation from.
  static Rect _getSheetRectBegin(
    Orientation? orientation,
    _ContextMenuLocation contextMenuLocation,
    Rect childRect,
    Rect sheetRect,
  ) {
    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        final Offset target = orientation == Orientation.portrait
            ? childRect.bottomCenter
            : childRect.topCenter;
        final Offset centered = target - Offset(sheetRect.width / 2, 0.0);
        return centered & sheetRect.size;
      case _ContextMenuLocation.right:
        final Offset target = orientation == Orientation.portrait
            ? childRect.bottomRight
            : childRect.topRight;
        return (target - Offset(sheetRect.width, 0.0)) & sheetRect.size;
      case _ContextMenuLocation.left:
        final Offset target = orientation == Orientation.portrait
            ? childRect.bottomLeft
            : childRect.topLeft;
        return target & sheetRect.size;
    }
  }

  void _onDismiss(BuildContext context, double scale, double opacity) {
    _scale = scale;
    _opacityTween.end = opacity;
    _sheetOpacity = _opacityTween.animate(
      CurvedAnimation(
        parent: animation!,
        curve: const Interval(0.9, 1.0),
      ),
    );
    Navigator.of(context).pop();
  }

  // Take measurements on the child and _ContextMenuSheet and update the
  // animation tweens to match.
  void _updateTweenRects() {
    final Rect childRect = _scale == null
        ? _getRect(_childGlobalKey)
        : _getScaledRect(_childGlobalKey, _scale!);
    _rectTween.begin = _previousChildRect;
    _rectTween.end = childRect;

    // When opening, the transition happens from the end of the child's bounce
    // animation to the final state. When closing, it goes from the final state
    // to the original position before the bounce.
    final Rect childRectOriginal = Rect.fromCenter(
      center: _previousChildRect.center,
      width: _previousChildRect.width / _kOpenScale,
      height: _previousChildRect.height / _kOpenScale,
    );

    final Rect sheetRect = _getRect(_sheetGlobalKey);
    final Rect sheetRectBegin = _getSheetRectBegin(
      _lastOrientation,
      _contextMenuLocation,
      childRectOriginal,
      sheetRect,
    );
    _sheetRectTween.begin = sheetRectBegin;
    _sheetRectTween.end = sheetRect;
    _sheetScaleTween.begin = 0.0;
    _sheetScaleTween.end = _scale;

    _rectTweenReverse.begin = childRectOriginal;
    _rectTweenReverse.end = childRect;
  }

  void _setOffstageInternally() {
    super.offstage = _externalOffstage || _internalOffstage;
    // It's necessary to call changedInternalState to get the backdrop to
    // update.
    changedInternalState();
  }

  @override
  bool didPop(T? result) {
    _updateTweenRects();
    return super.didPop(result);
  }

  @override
  set offstage(bool value) {
    _externalOffstage = value;
    _setOffstageInternally();
  }

  @override
  TickerFuture didPush() {
    _internalOffstage = true;
    _setOffstageInternally();

    // Render one frame offstage in the final position so that we can take
    // measurements of its layout and then animate to them.
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _updateTweenRects();
      _internalOffstage = false;
      _setOffstageInternally();
    });
    return super.didPush();
  }

  @override
  Animation<double> createAnimation() {
    final Animation<double> animation = super.createAnimation();
    _sheetOpacity = _opacityTween.animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
      ),
    );
    return animation;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    // This is usually used to build the "page", which is then passed to
    // buildTransitions as child, the idea being that buildTransitions will
    // animate the entire page into the scene. In the case of _ContextMenuRoute,
    // two individual pieces of the page are animated into the scene in
    // buildTransitions, and a SizedBox.shrink() is returned here.
    return const SizedBox.shrink();
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return OrientationBuilder(
      builder: (BuildContext context, Orientation orientation) {
        _lastOrientation = orientation;

        // While the animation is running, render everything in a Stack so that
        // they're movable.
        if (!animation.isCompleted) {
          final bool reverse = animation.status == AnimationStatus.reverse;
          final Rect rect = reverse
              ? _rectAnimatableReverse.evaluate(animation)!
              : _rectAnimatable.evaluate(animation)!;
          final Rect sheetRect = reverse
              ? _sheetRectAnimatableReverse.evaluate(animation)!
              : _sheetRectAnimatable.evaluate(animation)!;
          final double sheetScale = reverse
              ? _sheetScaleAnimatableReverse.evaluate(animation)
              : _sheetScaleAnimatable.evaluate(animation);
          return Stack(
            children: <Widget>[
              Positioned.fromRect(
                rect: sheetRect,
                child: FadeTransition(
                  opacity: _sheetOpacity,
                  child: Transform.scale(
                    alignment: getSheetAlignment(_contextMenuLocation),
                    scale: sheetScale,
                    child: _ContextMenuSheet(
                      key: _sheetGlobalKey,
                      actions: _actions,
                      contextMenuLocation: _contextMenuLocation,
                      orientation: orientation,
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                key: _childGlobalKey,
                rect: rect,
                child: _builder!(context, animation),
              ),
            ],
          );
        }

        // When the animation is done, just render everything in a static layout
        // in the final position.
        return _ContextMenuRouteStatic(
          actions: _actions,
          childGlobalKey: _childGlobalKey,
          contextMenuLocation: _contextMenuLocation,
          onDismiss: _onDismiss,
          orientation: orientation,
          sheetGlobalKey: _sheetGlobalKey,
          child: _builder!(context, animation),
        );
      },
    );
  }
}

// The final state of the _ContextMenuRoute after animating in and before
// animating out.
class _ContextMenuRouteStatic extends StatefulWidget {
  const _ContextMenuRouteStatic({
    this.actions,
    required this.child,
    this.childGlobalKey,
    required this.contextMenuLocation,
    this.onDismiss,
    required this.orientation,
    this.sheetGlobalKey,
  });

  final List<Widget>? actions;
  final Widget child;
  final GlobalKey? childGlobalKey;
  final _ContextMenuLocation contextMenuLocation;
  final _DismissCallback? onDismiss;
  final Orientation orientation;
  final GlobalKey? sheetGlobalKey;

  @override
  _ContextMenuRouteStaticState createState() => _ContextMenuRouteStaticState();
}

class _ContextMenuRouteStaticState extends State<_ContextMenuRouteStatic>
    with TickerProviderStateMixin {
  // The child is scaled down as it is dragged down until it hits this minimum
  // value.
  static const double _kMinScale = 0.8;
  // The CupertinoContextMenuSheet disappears at this scale.
  static const double _kSheetScaleThreshold = 0.9;
  static const double _kPadding = 20.0;
  static const double _kDamping = 400.0;
  static const Duration _kMoveControllerDuration = Duration(milliseconds: 600);

  late Offset _dragOffset;
  double _lastScale = 1.0;
  late AnimationController _moveController;
  late AnimationController _sheetController;
  late Animation<Offset> _moveAnimation;
  late Animation<double> _sheetScaleAnimation;
  late Animation<double> _sheetOpacityAnimation;

  // The scale of the child changes as a function of the distance it is dragged.
  static double _getScale(
    Orientation orientation,
    double maxDragDistance,
    double dy,
  ) {
    final double dyDirectional = dy <= 0.0 ? dy : -dy;
    return math.max(
      _kMinScale,
      (maxDragDistance + dyDirectional) / maxDragDistance,
    );
  }

  void _onPanStart(DragStartDetails details) {
    _moveController.value = 1.0;
    _setDragOffset(Offset.zero);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _setDragOffset(_dragOffset + details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    // If flung, animate a bit before handling the potential dismiss.
    if (details.velocity.pixelsPerSecond.dy.abs() >= kMinFlingVelocity) {
      final bool flingIsAway = details.velocity.pixelsPerSecond.dy > 0;
      final double finalPosition =
          flingIsAway ? _moveAnimation.value.dy + 100.0 : 0.0;

      if (flingIsAway && _sheetController.status != AnimationStatus.forward) {
        _sheetController.forward();
      } else if (!flingIsAway &&
          _sheetController.status != AnimationStatus.reverse) {
        _sheetController.reverse();
      }

      _moveAnimation = Tween<Offset>(
        begin: Offset(0.0, _moveAnimation.value.dy),
        end: Offset(0.0, finalPosition),
      ).animate(_moveController);
      _moveController.reset();
      _moveController.duration = const Duration(
        milliseconds: 64,
      );
      _moveController.forward();
      _moveController.addStatusListener(_flingStatusListener);
      return;
    }

    // Dismiss if the drag is enough to scale down all the way.
    if (_lastScale == _kMinScale) {
      widget.onDismiss!(context, _lastScale, _sheetOpacityAnimation.value);
      return;
    }

    // Otherwise animate back home.
    _moveController.addListener(_moveListener);
    _moveController.reverse();
  }

  void _moveListener() {
    // When the scale passes the threshold, animate the sheet back in.
    if (_lastScale > _kSheetScaleThreshold) {
      _moveController.removeListener(_moveListener);
      if (_sheetController.status != AnimationStatus.dismissed) {
        _sheetController.reverse();
      }
    }
  }

  void _flingStatusListener(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    // Reset the duration back to its original value.
    _moveController.duration = _kMoveControllerDuration;

    _moveController.removeStatusListener(_flingStatusListener);
    // If it was a fling back to the start, it has reset itself, and it should
    // not be dismissed.
    if (_moveAnimation.value.dy == 0.0) {
      return;
    }
    widget.onDismiss!(context, _lastScale, _sheetOpacityAnimation.value);
  }

  Alignment _getChildAlignment(
    Orientation orientation,
    _ContextMenuLocation contextMenuLocation,
  ) {
    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        return orientation == Orientation.portrait
            ? Alignment.bottomCenter
            : Alignment.topRight;
      case _ContextMenuLocation.right:
        return orientation == Orientation.portrait
            ? Alignment.bottomCenter
            : Alignment.topLeft;
      case _ContextMenuLocation.left:
        return orientation == Orientation.portrait
            ? Alignment.bottomCenter
            : Alignment.topRight;
    }
  }

  void _setDragOffset(Offset dragOffset) {
    // Allow horizontal and negative vertical movement, but damp it.
    final double endX = _kPadding * dragOffset.dx / _kDamping;
    final double endY = dragOffset.dy >= 0.0
        ? dragOffset.dy
        : _kPadding * dragOffset.dy / _kDamping;
    setState(() {
      _dragOffset = dragOffset;
      _moveAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(
          clampDouble(endX, -_kPadding, _kPadding),
          endY,
        ),
      ).animate(
        CurvedAnimation(
          parent: _moveController,
          curve: Curves.elasticIn,
        ),
      );

      // Fade the _ContextMenuSheet out or in, if needed.
      if (_lastScale <= _kSheetScaleThreshold &&
          _sheetController.status != AnimationStatus.forward &&
          _sheetScaleAnimation.value != 0.0) {
        _sheetController.forward();
      } else if (_lastScale > _kSheetScaleThreshold &&
          _sheetController.status != AnimationStatus.reverse &&
          _sheetScaleAnimation.value != 1.0) {
        _sheetController.reverse();
      }
    });
  }

  // The order and alignment of the _ContextMenuSheet and the child depend on
  // both the orientation of the screen as well as the position on the screen of
  // the original child.
  List<Widget> _getChildren(
    Orientation orientation,
    _ContextMenuLocation contextMenuLocation,
  ) {
    final Expanded child = Expanded(
      child: Align(
        alignment: _getChildAlignment(
          widget.orientation,
          widget.contextMenuLocation,
        ),
        child: AnimatedBuilder(
          animation: _moveController,
          builder: _buildChildAnimation,
          child: widget.child,
        ),
      ),
    );
    const SizedBox spacer = SizedBox(
      width: _kPadding,
      height: _kPadding,
    );
    final Expanded sheet = Expanded(
      child: AnimatedBuilder(
        animation: _sheetController,
        builder: _buildSheetAnimation,
        child: _ContextMenuSheet(
          key: widget.sheetGlobalKey,
          actions: widget.actions!,
          contextMenuLocation: widget.contextMenuLocation,
          orientation: widget.orientation,
        ),
      ),
    );

    switch (contextMenuLocation) {
      case _ContextMenuLocation.center:
        return <Widget>[child, spacer, sheet];
      case _ContextMenuLocation.right:
        return orientation == Orientation.portrait
            ? <Widget>[child, spacer, sheet]
            : <Widget>[sheet, spacer, child];
      case _ContextMenuLocation.left:
        return <Widget>[child, spacer, sheet];
    }
  }

  // Build the animation for the _ContextMenuSheet.
  Widget _buildSheetAnimation(BuildContext context, Widget? child) {
    return Transform.scale(
      alignment:
          _ContextMenuRoute.getSheetAlignment(widget.contextMenuLocation),
      scale: _sheetScaleAnimation.value,
      child: FadeTransition(
        opacity: _sheetOpacityAnimation,
        child: child,
      ),
    );
  }

  // Build the animation for the child.
  Widget _buildChildAnimation(BuildContext context, Widget? child) {
    _lastScale = _getScale(
      widget.orientation,
      MediaQuery.sizeOf(context).height,
      _moveAnimation.value.dy,
    );
    return Transform.scale(
      key: widget.childGlobalKey,
      scale: _lastScale,
      child: child,
    );
  }

  // Build the animation for the overall draggable dismissible content.
  Widget _buildAnimation(BuildContext context, Widget? child) {
    return Transform.translate(
      offset: _moveAnimation.value,
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      duration: _kMoveControllerDuration,
      value: 1.0,
      vsync: this,
    );
    _sheetController = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _sheetScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _sheetController,
        curve: Curves.linear,
        reverseCurve: Curves.easeInBack,
      ),
    );
    _sheetOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_sheetController);
    _setDragOffset(Offset.zero);
  }

  @override
  void dispose() {
    _moveController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = _getChildren(
      widget.orientation,
      widget.contextMenuLocation,
    );

    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: GestureDetector(
          onPanEnd: _onPanEnd,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          child: AnimatedBuilder(
            animation: _moveController,
            builder: _buildAnimation,
            child: widget.orientation == Orientation.portrait
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: children,
                  ),
          ),
        ),
      ),
    );
  }
}

// The menu that displays when LichessCupertinoContextMenu is open. It consists of a
// list of actions that are typically CupertinoContextMenuActions.
class _ContextMenuSheet extends StatelessWidget {
  _ContextMenuSheet({
    super.key,
    required this.actions,
    required _ContextMenuLocation contextMenuLocation,
    required Orientation orientation,
  })  : assert(actions.isNotEmpty),
        _contextMenuLocation = contextMenuLocation,
        _orientation = orientation;

  final List<Widget> actions;
  final _ContextMenuLocation _contextMenuLocation;
  final Orientation _orientation;

  static const double _kMenuWidth = 250.0;

  // Get the children, whose order depends on orientation and
  // contextMenuLocation.
  List<Widget> getChildren(BuildContext context) {
    final Widget menu = SizedBox(
      width: _kMenuWidth,
      child: IntrinsicHeight(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(13.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              actions.first,
              for (final Widget action in actions.skip(1))
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: CupertinoDynamicColor.resolve(
                          _borderColor,
                          context,
                        ),
                        width: 0.4,
                      ),
                    ),
                  ),
                  position: DecorationPosition.foreground,
                  child: action,
                ),
            ],
          ),
        ),
      ),
    );

    switch (_contextMenuLocation) {
      case _ContextMenuLocation.center:
        return _orientation == Orientation.portrait
            ? <Widget>[
                const Spacer(),
                menu,
                const Spacer(),
              ]
            : <Widget>[
                menu,
                const Spacer(),
              ];
      case _ContextMenuLocation.right:
        return <Widget>[
          const Spacer(),
          menu,
        ];
      case _ContextMenuLocation.left:
        return <Widget>[
          menu,
          const Spacer(),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: getChildren(context),
    );
  }
}
