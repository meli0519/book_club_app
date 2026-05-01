import 'package:flutter/material.dart';

/// A decorative divider with mystical elements inspired by the logo.
/// Features stars and a flowing line reminiscent of the serpent/smoke.
class MysticalDivider extends StatelessWidget {
  final double height;
  final Color? color;

  const MysticalDivider({
    this.height = 40,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? theme.colorScheme.primary;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _WavyLinePainter(color: dividerColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.auto_stories,
              color: dividerColor,
              size: 20,
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _WavyLinePainter(color: dividerColor, reverse: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _WavyLinePainter extends CustomPainter {
  final Color color;
  final bool reverse;

  _WavyLinePainter({
    required this.color,
    this.reverse = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    if (reverse) {
      path.moveTo(size.width, size.height / 2);
      
      for (double x = size.width; x >= 0; x -= 10) {
        final y = size.height / 2 + 
            (x / size.width * 8 * (x % 20 < 10 ? 1 : -1));
        path.lineTo(x, y);
      }
    } else {
      path.moveTo(0, size.height / 2);
      
      for (double x = 0; x <= size.width; x += 10) {
        final y = size.height / 2 + 
            (x / size.width * 8 * (x % 20 < 10 ? 1 : -1));
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavyLinePainter oldDelegate) => false;
}
