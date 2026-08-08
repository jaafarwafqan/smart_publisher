import 'package:flutter/widgets.dart';

class AdaptiveContentWidth extends StatelessWidget {
  const AdaptiveContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 1120,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth > maxWidth
            ? maxWidth
            : constraints.maxWidth;

        return Align(
          alignment: AlignmentDirectional.topCenter,
          child: SizedBox(width: contentWidth, child: child),
        );
      },
    );
  }
}
