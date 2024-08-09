import 'package:flutter/material.dart';

import '../utils/avatar_generator.dart';

class CustomAvatar extends StatelessWidget {
  final String userId;
  final String username;
  final double size;

  const CustomAvatar({
    super.key,
    required this.userId,
    required this.username,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final color = AvatarGenerator.generateColor(userId);
    final initials = AvatarGenerator.getInitials(username);

    return CustomPaint(
      size: Size(size, size),
      painter: AvatarPainter(
        backgroundColor: color,
        initials: initials,
      ),
    );
  }
}

class AvatarPainter extends CustomPainter {
  final Color backgroundColor;
  final String initials;

  AvatarPainter({required this.backgroundColor, required this.initials});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = backgroundColor;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
