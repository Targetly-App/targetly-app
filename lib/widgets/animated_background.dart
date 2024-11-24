import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final double blur;
  final Color baseColor;
  final int numberOfBubbles;

  const AnimatedBackground({
    Key? key,
    this.blur = 30,
    this.baseColor = const Color(0xFF9E6BFE),
    this.numberOfBubbles = 20,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<Bubble> _bubbles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      widget.numberOfBubbles,
      (index) => AnimationController(
        duration: Duration(seconds: _random.nextInt(10) + 10),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      );
    }).toList();

    _bubbles = List.generate(
      widget.numberOfBubbles,
      (index) => Bubble(
        startPosition: _randomPosition(),
        endPosition: _randomPosition(),
        size: _random.nextDouble() * 100 + 50,
        color: widget.baseColor.withOpacity(_random.nextDouble() * 0.4 + 0.1),
      ),
    );

    for (var controller in _controllers) {
      controller.repeat(reverse: true);
    }
  }

  Offset _randomPosition() {
    return Offset(
      _random.nextDouble() * 2 - 0.5,
      _random.nextDouble() * 2 - 0.5,
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: widget.baseColor.withOpacity(0.1)),
        ...List.generate(
          widget.numberOfBubbles,
          (index) => AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              final bubble = _bubbles[index];
              final position = Offset.lerp(
                bubble.startPosition,
                bubble.endPosition,
                _animations[index].value,
              )!;

              return Positioned(
                left: MediaQuery.of(context).size.width * (0.5 + position.dx),
                top: MediaQuery.of(context).size.height * (0.5 + position.dy),
                child: Transform.scale(
                  scale: 1.0 + _animations[index].value * 0.2,
                  child: Container(
                    width: bubble.size,
                    height: bubble.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bubble.color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class Bubble {
  final Offset startPosition;
  final Offset endPosition;
  final double size;
  final Color color;

  Bubble({
    required this.startPosition,
    required this.endPosition,
    required this.size,
    required this.color,
  });
}
