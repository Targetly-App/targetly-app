import 'dart:math';

import 'package:flutter/material.dart';

class Star {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double blur;

  Star({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.blur,
  });
}

class FallingStarsBackground extends StatefulWidget {
  final Widget child;
  final int numberOfStars;
  final double maxBlur;
  final Color starColor;

  const FallingStarsBackground({
    Key? key,
    required this.child,
    this.numberOfStars = 50,
    this.maxBlur = 3.0,
    this.starColor = Colors.white,
  }) : super(key: key);

  @override
  State<FallingStarsBackground> createState() => _FallingStarsBackgroundState();
}

class _FallingStarsBackgroundState extends State<FallingStarsBackground>
    with SingleTickerProviderStateMixin {
  late List<Star> stars;
  late AnimationController _controller;
  final Random random = Random();
  final double screenHeight = 800.0; // You might want to make this dynamic

  @override
  void initState() {
    super.initState();
    stars = List.generate(widget.numberOfStars, (_) => _createStar(true));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(_updateStars);
  }

  Star _createStar(bool initial) {
    double y = initial ? random.nextDouble() * screenHeight : -20.0;
    return Star(
      x: random.nextDouble() * 400,
      y: y,
      speed: 1 + random.nextDouble() * 3,
      size: 1 + random.nextDouble() * 2,
      opacity: 1.0,
      blur: random.nextDouble() * widget.maxBlur,
    );
  }

  void _updateStars() {
    if (!mounted) return;

    setState(() {
      for (var i = 0; i < stars.length; i++) {
        stars[i].y += stars[i].speed;

        // Calculate opacity with bounds checking
        double calculatedOpacity = 1.0 - (stars[i].y / screenHeight);
        stars[i].opacity = calculatedOpacity.clamp(0.0, 1.0);

        // Reset star when it goes off screen or becomes transparent
        if (stars[i].y > screenHeight || stars[i].opacity <= 0) {
          stars[i] = _createStar(false);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: StarsPainter(
                stars: stars,
                starColor: widget.starColor,
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class StarsPainter extends CustomPainter {
  final List<Star> stars;
  final Color starColor;

  StarsPainter({required this.stars, required this.starColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      // Ensure opacity is within valid range
      final safeOpacity = star.opacity.clamp(0.0, 1.0);

      if (safeOpacity <= 0.0) continue; // Skip invisible stars

      final paint = Paint()
        ..color = starColor.withOpacity(safeOpacity)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          star.blur.clamp(0.0, 10.0), // Prevent excessive blur values
        );

      canvas.drawCircle(
        Offset(star.x, star.y),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StarsPainter oldDelegate) => true;
}
