import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'design.dart';

/// Original, decorative illustrations. None represents live service status.
enum DeskSceneKind { accounts, opening, privacy }

bool _reduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ||
    MediaQuery.accessibleNavigationOf(context);

/// A brief local Lottie illustration that keeps its completed artwork visible.
///
/// This belongs inside an already opaque privacy cover, never around the cover
/// itself or around a native session view.
class DeskScene extends StatefulWidget {
  const DeskScene({super.key, required this.kind, this.size = 160});

  final DeskSceneKind kind;
  final double size;

  @override
  State<DeskScene> createState() => _DeskSceneState();
}

class _DeskSceneState extends State<DeskScene>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _loaded = false;
  bool _reduced = false;
  bool _visible = true;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = _reduceMotion(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _syncPlayback();
  }

  @override
  void didUpdateWidget(DeskScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind) {
      _loaded = false;
      _controller.stop();
      _controller.value = _reduced ? 1 : 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  void _syncPlayback() {
    if (_reduced) {
      _controller.stop();
      _controller.value = 1;
    } else if (_loaded && _visible && _resumed && _controller.value < 1) {
      if (!_controller.isAnimating) _controller.forward();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox.square(
        dimension: widget.size,
        child: Lottie.asset(
          'assets/animations/${widget.kind.name}.json',
          key: ValueKey(widget.kind),
          controller: _controller,
          repeat: false,
          frameRate: FrameRate.composition,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            _loaded = true;
            _syncPlayback();
          },
          frameBuilder: (context, child, composition) => composition == null
              ? _SceneFallback(kind: widget.kind, size: widget.size)
              : child,
          errorBuilder: (context, error, stackTrace) =>
              _SceneFallback(kind: widget.kind, size: widget.size),
        ),
      ),
    ),
  );
}

class _SceneFallback extends StatelessWidget {
  const _SceneFallback({required this.kind, required this.size});

  final DeskSceneKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: size * .62,
        height: size * .62,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(size * .18),
        ),
        alignment: Alignment.center,
        child: DeskIcon(
          switch (kind) {
            DeskSceneKind.accounts => 'apps',
            DeskSceneKind.opening => 'device-mobile',
            DeskSceneKind.privacy => 'shield-lock',
          },
          size: size * .26,
          color: colors.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// A small, finite entrance for editorial content, never a security boundary.
class DeskEntrance extends StatefulWidget {
  const DeskEntrance({super.key, required this.child, this.order = 0});

  final Widget child;
  final int order;

  @override
  State<DeskEntrance> createState() => _DeskEntranceState();
}

class _DeskEntranceState extends State<DeskEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _configure();
  }

  void _configure() {
    final stagger = (widget.order * 30).clamp(0, 120);
    final duration = 280 + stagger;
    _controller.duration = Duration(milliseconds: duration);
    _progress = _controller.drive(
      CurveTween(
        curve: Interval(stagger / duration, 1, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(DeskEntrance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order != widget.order) _configure();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _progress,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _progress.value,
      alwaysIncludeSemantics: true,
      child: Transform.translate(
        offset: Offset(0, 8 * (1 - _progress.value)),
        child: child,
      ),
    ),
  );
}

/// Adds tactile visual feedback while leaving the child's gesture arena alone.
class DeskTapFeedback extends StatefulWidget {
  const DeskTapFeedback({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<DeskTapFeedback> createState() => _DeskTapFeedbackState();
}

class _DeskTapFeedbackState extends State<DeskTapFeedback>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 160),
  );
  final Set<int> _pointers = {};
  bool _reduced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = _reduceMotion(context);
    if (_reduced) {
      _pointers.clear();
      _controller.value = 0;
    }
  }

  @override
  void didUpdateWidget(DeskTapFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _pointers.clear();
      _controller.value = 0;
    }
  }

  void _press(PointerDownEvent event) {
    if (!widget.enabled || _reduced) return;
    _pointers.add(event.pointer);
    _controller.forward();
  }

  void _release(PointerEvent event) {
    _pointers.remove(event.pointer);
    if (_pointers.isEmpty) _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _press,
    onPointerUp: _release,
    onPointerCancel: _release,
    child: AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: 1 - .025 * Curves.easeOutCubic.transform(_controller.value),
        child: child,
      ),
    ),
  );
}

/// A restrained Tabler icon nudge when selection changes; never a repeating loop.
class DeskAnimatedIcon extends StatefulWidget {
  const DeskAnimatedIcon(
    this.name, {
    super.key,
    this.active = false,
    this.size = 22,
    this.color,
  });

  final String name;
  final bool active;
  final double size;
  final Color? color;

  @override
  State<DeskAnimatedIcon> createState() => _DeskAnimatedIconState();
}

class _DeskAnimatedIconState extends State<DeskAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  bool _reduced = false;
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = _reduceMotion(context);
    if (_reduced) {
      _controller.value = 1;
    } else if (!_entered && widget.active) {
      _controller.forward(from: 0);
    }
    _entered = true;
  }

  @override
  void didUpdateWidget(DeskAnimatedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (_reduced) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: DeskIcon(widget.name, size: widget.size, color: widget.color),
    builder: (context, child) {
      final emphasis = math.sin(_controller.value * math.pi);
      return Transform.rotate(
        angle: emphasis * .10 * (widget.active ? 1 : -1),
        child: Transform.scale(scale: 1 + emphasis * .08, child: child),
      );
    },
  );
}
