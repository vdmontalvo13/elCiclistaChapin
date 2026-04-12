import 'package:flutter/material.dart';

/// Constrains content to a mobile-like width on wide screens (web/desktop).
/// On screens narrower than [maxWidth], renders the child unchanged.
/// On wider screens, centers the child at [maxWidth] width.
///
/// Uses a Row + Spacer approach internally to preserve tight height constraints,
/// which allows Column widgets with Expanded children to work correctly.
class WebFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebFrame({
    super.key,
    required this.child,
    this.maxWidth = 500.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) return child;
        return Row(
          children: [
            const Spacer(),
            SizedBox(width: maxWidth, child: child),
            const Spacer(),
          ],
        );
      },
    );
  }
}
