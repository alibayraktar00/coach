import 'package:flutter/material.dart';
import '../../core/utils/glass_morphism.dart';

class IconGlassButton extends StatelessWidget {
  const IconGlassButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(10),
        borderRadius: BorderRadius.circular(18),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
