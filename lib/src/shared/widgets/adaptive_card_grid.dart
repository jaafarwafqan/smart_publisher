import 'package:flutter/material.dart';

/// A card grid with a logical, width-driven column count that never leaves
/// the wasted-space layout a bare `Wrap` of fixed-width cards produces:
/// a single card floating alone in a row built for 3-4, or a trailing row
/// of leftover cards that don't stretch to fill it (audit finding,
/// 2026-08-12: "single accounts card with a large gap" / platform metric
/// cards rendering "4 then 2, wasting space").
///
/// Column count is picked from [breakpoints] by available width, then
/// capped at `items.length` — so 1 item always fills the full row width,
/// 2 items split it in half, and so on, instead of leaving the remainder
/// of a wider row empty. Every card in a row shares equal width.
class AdaptiveCardGrid extends StatelessWidget {
  const AdaptiveCardGrid({
    super.key,
    required this.items,
    this.spacing = 12,
    this.runSpacing = 12,
    this.breakpoints = const <AdaptiveGridBreakpoint>[
      AdaptiveGridBreakpoint(minWidth: 900, columns: 4),
      AdaptiveGridBreakpoint(minWidth: 640, columns: 2),
      AdaptiveGridBreakpoint(minWidth: 0, columns: 1),
    ],
  });

  final List<Widget> items;
  final double spacing;
  final double runSpacing;

  /// Must be sorted by descending `minWidth` — the first entry whose
  /// `minWidth` the available width satisfies wins.
  final List<AdaptiveGridBreakpoint> breakpoints;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final widthColumns = breakpoints
            .firstWhere(
              (b) => constraints.maxWidth >= b.minWidth,
              orElse: () => breakpoints.last,
            )
            .columns;
        final columns = widthColumns.clamp(1, items.length);
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: items
              .map((item) => SizedBox(width: cardWidth, child: item))
              .toList(growable: false),
        );
      },
    );
  }
}

class AdaptiveGridBreakpoint {
  const AdaptiveGridBreakpoint({required this.minWidth, required this.columns});
  final double minWidth;
  final int columns;
}
