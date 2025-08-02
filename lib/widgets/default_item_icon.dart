import 'package:flutter/material.dart';

class DefaultItemIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const DefaultItemIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/icon.png',
        width: size,
        height: size,
        color: color,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to emoji if image fails to load
          return Text(
            '🍽️',
            style: TextStyle(fontSize: size * 0.8),
          );
        },
      ),
    );
  }
}