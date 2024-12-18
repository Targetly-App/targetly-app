import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedStackedCards extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final int maxVisibleCards;
  final double scaleFactor;
  final bool isExpanded;
  final Function(bool)? onExpandChanged;
  final Function()? onTap;

  const AnimatedStackedCards({
    super.key,
    required this.children,
    this.spacing = 10.0,
    this.maxVisibleCards = 3,
    this.scaleFactor = 0.03,
    required this.isExpanded,
    this.onExpandChanged,
    this.onTap,
  });

  @override
  State<AnimatedStackedCards> createState() => _AnimatedStackedCardsState();
}

class _AnimatedStackedCardsState extends State<AnimatedStackedCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  final Map<int, GlobalKey> _keys = {};
  Map<int, double> _cachedHeights = {};
  bool _hasInitialHeight = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    for (int i = 0; i < widget.children.length; i++) {
      _keys[i] = GlobalKey();
    }

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedStackedCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _getHeight(int index) {
    if (_cachedHeights.containsKey(index)) {
      return _cachedHeights[index]!;
    }

    final RenderBox? renderBox =
        _keys[index]?.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox != null) {
      _cachedHeights[index] = renderBox.size.height;
      return _cachedHeights[index]!;
    }

    return !_hasInitialHeight ? 80.0 : _cachedHeights[0] ?? 80.0;
  }

  void _toggleExpanded() {
    final newState = !widget.isExpanded;
    widget.onExpandChanged?.call(newState);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleCards = widget.children.length > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            if (!_hasInitialHeight) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  for (int i = 0; i < widget.children.length; i++) {
                    final RenderBox? renderBox = _keys[i]
                        ?.currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (renderBox != null) {
                      _cachedHeights[i] = renderBox.size.height;
                    }
                  }
                  _hasInitialHeight = true;
                });
              });
            }

            final firstCardHeight = _getHeight(0);
            final maxStackHeight = firstCardHeight +
                (widget.spacing * (widget.maxVisibleCards - 1));

            double totalListHeight = 0;
            for (int i = 0; i < widget.children.length; i++) {
              totalListHeight += _getHeight(i);
            }

            final visibleStackItems =
                min(widget.maxVisibleCards, widget.children.length);
            final stackSpacing = widget.spacing;

            final stackViewHeight =
                firstCardHeight + (stackSpacing * (visibleStackItems - 1));
            final currentHeight = stackViewHeight +
                (totalListHeight - stackViewHeight) * _expandAnimation.value;

            final List<Widget> stackItems = [];

            for (int i = 0; i < widget.children.length; i++) {
              final reverseIndex = widget.children.length - 1 - i;
              final isVisibleInStack = reverseIndex < widget.maxVisibleCards;

              final stackPosition = isVisibleInStack
                  ? (widget.maxVisibleCards - 1 - reverseIndex) * stackSpacing
                  : 0;

              double listPosition = 0;
              for (int j = 0; j < i; j++) {
                listPosition += _getHeight(j);
              }

              final progress =
                  Curves.easeInOutCubic.transform(_expandAnimation.value);
              final currentPosition =
                  stackPosition + (listPosition - stackPosition) * progress;

              final stackScale = 1.0 -
                  (widget.scaleFactor *
                      reverseIndex *
                      (isVisibleInStack ? 1 : 0));
              final listScale = 1.0;
              final scale = stackScale + (listScale - stackScale) * progress;

              final opacity =
                  i < widget.children.length - widget.maxVisibleCards
                      ? _expandAnimation.value
                      : 1.0;

              if (opacity > 0) {
                stackItems.add(
                  Positioned(
                    top: currentPosition,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topCenter,
                        child: Container(
                          key: _keys[i],
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26
                                    .withOpacity(0.26 * (1 - progress)),
                                blurRadius: 4,
                                offset: const Offset(0, -4),
                                spreadRadius: reverseIndex == 0 ? 0.5 : 0,
                              ),
                            ],
                          ),
                          child: widget.children[i],
                        ),
                      ),
                    ),
                  ),
                );
              }
            }

            return GestureDetector(
              onTap: hasMultipleCards ? _toggleExpanded : null,
              child: SizedBox(
                width: constraints.maxWidth,
                height: currentHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: stackItems,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
