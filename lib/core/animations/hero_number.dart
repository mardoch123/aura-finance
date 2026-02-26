import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget qui anime un chiffre de oldValue vers newValue
/// avec une animation de compteur fluide
///
/// Usage:
/// ```dart
/// HeroNumber(
///   value: balance,
///   prefix: '€',
///   style: AuraTypography.amountLarge,
/// )
/// ```
class HeroNumber extends StatefulWidget {
  const HeroNumber({
    super.key,
    required this.value,
    this.oldValue,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 2,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutExpo,
    this.style,
    this.textAlign = TextAlign.start,
    this.animateOnInit = true,
  });

  /// Valeur actuelle à afficher
  final double value;

  /// Valeur précédente (pour l'animation)
  final double? oldValue;

  /// Préfixe (ex: '€', '$')
  final String prefix;

  /// Suffixe (ex: '%')
  final String suffix;

  /// Nombre de décimales à afficher
  final int decimals;

  /// Durée de l'animation
  final Duration duration;

  /// Courbe d'animation
  final Curve curve;

  /// Style du texte
  final TextStyle? style;

  /// Alignement du texte
  final TextAlign textAlign;

  /// Animer lors de l'initialisation
  final bool animateOnInit;

  @override
  State<HeroNumber> createState() => _HeroNumberState();
}

class _HeroNumberState extends State<HeroNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0.0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.oldValue ?? 0.0;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.animateOnInit) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(HeroNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatNumber(double value) {
    final absValue = value.abs();
    final sign = value < 0 ? '-' : '';
    
    // Format avec séparateurs de milliers
    final integerPart = absValue.toInt();
    final decimalPart = ((absValue - integerPart) * math.pow(10, widget.decimals))
        .round()
        .toString()
        .padLeft(widget.decimals, '0');
    
    final formattedInteger = _formatWithSeparators(integerPart);
    
    if (widget.decimals > 0) {
      return '$sign$formattedInteger.$decimalPart';
    }
    return '$sign$formattedInteger';
  }

  String _formatWithSeparators(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _previousValue +
            (widget.value - _previousValue) * _animation.value;
        
        return Text(
          '${widget.prefix}${_formatNumber(currentValue)}${widget.suffix}',
          style: widget.style,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}

/// Version simplifiée pour les entiers
class HeroInt extends StatelessWidget {
  const HeroInt({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutExpo,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final int value;
  final String prefix;
  final String suffix;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return HeroNumber(
      value: value.toDouble(),
      prefix: prefix,
      suffix: suffix,
      decimals: 0,
      duration: duration,
      curve: curve,
      style: style,
      textAlign: textAlign,
    );
  }
}

/// Widget pour animer un pourcentage
class HeroPercent extends StatelessWidget {
  const HeroPercent({
    super.key,
    required this.value,
    this.decimals = 1,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutExpo,
    this.style,
    this.textAlign = TextAlign.start,
    this.showSign = false,
  });

  final double value;
  final int decimals;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final prefix = showSign && value > 0 ? '+' : '';
    
    return HeroNumber(
      value: value,
      prefix: prefix,
      suffix: '%',
      decimals: decimals,
      duration: duration,
      curve: curve,
      style: style,
      textAlign: textAlign,
    );
  }
}

/// Widget pour animer une différence avec indicateur de direction
class HeroDelta extends StatelessWidget {
  const HeroDelta({
    super.key,
    required this.value,
    this.positiveIsGood = true,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutExpo,
    this.style,
    this.textAlign = TextAlign.start,
  });

  final double value;
  final bool positiveIsGood;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final isGood = positiveIsGood ? isPositive : !isPositive;
    
    final icon = isPositive ? '▲' : '▼';
    final color = isGood ? Colors.green : Colors.red;
    
    return HeroNumber(
      value: value.abs(),
      prefix: '$icon ',
      suffix: '%',
      decimals: 1,
      duration: duration,
      curve: curve,
      style: (style ?? const TextStyle()).copyWith(color: color),
      textAlign: textAlign,
    );
  }
}
