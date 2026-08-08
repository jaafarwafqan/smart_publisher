import 'package:flutter/material.dart';

import '../../core/theme/app_curves.dart';
import '../../core/theme/app_duration.dart';

class AnimatedCountText extends StatefulWidget {
  const AnimatedCountText({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.fractionDigits = 0,
    this.duration = AppDuration.normal,
    this.curve = AppCurves.standard,
  });

  final num value;
  final TextStyle? style;
  final String suffix;
  final int fractionDigits;
  final Duration duration;
  final Curve curve;

  @override
  State<AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<AnimatedCountText> {
  late double _previousValue;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value.toDouble();
  }

  @override
  void didUpdateWidget(covariant AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previousValue, end: widget.value.toDouble()),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) {
        final formatted = widget.fractionDigits == 0
            ? value.round().toString()
            : value.toStringAsFixed(widget.fractionDigits);
        return Text('$formatted${widget.suffix}', style: widget.style);
      },
    );
  }
}
