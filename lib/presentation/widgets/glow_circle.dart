import 'package:flutter/material.dart';

class GlowCircle extends StatelessWidget {
  final Color color;
  final double size;

  const GlowCircle({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
        ),
      ),
    );
  }
}
