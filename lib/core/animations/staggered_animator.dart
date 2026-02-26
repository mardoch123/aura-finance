import 'package:flutter/material.dart';
import '../theme/aura_dimensions.dart';

/// Widget qui anime une liste de children avec un effet staggered
/// Chaque élément apparaît avec un délai progressif
/// 
/// Usage:
/// ```dart
/// StaggeredAnimator(
///   children: [
///     Text('Item 1'),
///     Text('Item 2'),
///     Text('Item 3'),
///   ],
/// )
/// ```
class StaggeredAnimator extends StatefulWidget {
  const StaggeredAnimator({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.axis = Axis.vertical,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
  });

  /// Liste des widgets à animer
  final List<Widget> children;

  /// Délai entre chaque animation
  final Duration delay;

  /// Durée de chaque animation
  final Duration duration;

  /// Courbe d'animation
  final Curve curve;

  /// Axe de disposition (vertical ou horizontal)
  final Axis axis;

  /// Alignement sur l'axe transversal
  final CrossAxisAlignment crossAxisAlignment;

  /// Alignement sur l'axe principal
  final MainAxisAlignment mainAxisAlignment;

  /// Taille sur l'axe principal
  final MainAxisSize mainAxisSize;

  @override
  State<StaggeredAnimator> createState() => _StaggeredAnimatorState();
}

class _StaggeredAnimatorState extends State<StaggeredAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.duration.inMilliseconds +
            (widget.children.length - 1) * widget.delay.inMilliseconds,
      ),
    );

    _animations = List.generate(
      widget.children.length,
      (index) {
        final start = index * widget.delay.inMilliseconds /
            _controller.duration!.inMilliseconds;
        final end = start +
            widget.duration.inMilliseconds /
                _controller.duration!.inMilliseconds;

        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              start.clamp(0.0, 1.0),
              end.clamp(0.0, 1.0),
              curve: widget.curve,
            ),
          ),
        );
      },
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children = List.generate(
      widget.children.length,
      (index) => _AnimatedItem(
        animation: _animations[index],
        child: widget.children[index],
      ),
    );

    if (widget.axis == Axis.vertical) {
      return Column(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: children,
      );
    } else {
      return Row(
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        mainAxisSize: widget.mainAxisSize,
        children: children,
      );
    }
  }
}

/// Widget interne pour animer chaque élément individuellement
class _AnimatedItem extends StatelessWidget {
  const _AnimatedItem({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Extension pour faciliter l'utilisation du staggered animator
extension StaggeredAnimatorExtension on List<Widget> {
  /// Convertit la liste en StaggeredAnimator
  Widget staggered({
    Duration delay = const Duration(milliseconds: 80),
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOutCubic,
    Axis axis = Axis.vertical,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  }) {
    return StaggeredAnimator(
      delay: delay,
      duration: duration,
      curve: curve,
      axis: axis,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment: mainAxisAlignment,
      children: this,
    );
  }
}

/// Version simplifiée pour animer un seul widget avec fade + slide
class FadeSlideAnimator extends StatefulWidget {
  const FadeSlideAnimator({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.slideOffset = const Offset(0, 20),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Offset slideOffset;

  @override
  State<FadeSlideAnimator> createState() => _FadeSlideAnimatorState();
}

class _FadeSlideAnimatorState extends State<FadeSlideAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(
              widget.slideOffset.dx * (1 - _animation.value),
              widget.slideOffset.dy * (1 - _animation.value),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
