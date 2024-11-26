import 'dart:math';

import 'package:flutter/material.dart';

class AnimatedStackedCards extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final int maxVisibleCards;
  final double scaleFactor;
  final bool isExpanded; // External state control
  final Function(bool)? onExpandChanged; // Callback for state changes
  final Function()? onTap; // Optional tap callback

  const AnimatedStackedCards({
    super.key,
    required this.children,
    this.spacing = 15.0,
    this.maxVisibleCards = 3,
    this.scaleFactor = 0.03,
    required this.isExpanded, // Make it required
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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    for (int i = 0; i < widget.children.length; i++) {
      _keys[i] = GlobalKey();
    }

    // Set initial state
    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedStackedCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    // React to external state changes
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

    return !_hasInitialHeight ? 120.0 : _cachedHeights[0] ?? 120.0;
  }

  void _toggleExpanded() {
    final newState = !widget.isExpanded;
    widget.onExpandChanged?.call(newState);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleCards = widget.children.length > 1;
    final visibleCount = min(widget.children.length, widget.maxVisibleCards);

    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            if (!_hasInitialHeight) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  for (int i = 0; i < visibleCount; i++) {
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

            double totalListHeight = 0;
            for (int i = 0; i < visibleCount; i++) {
              totalListHeight += _getHeight(i);
            }

            final firstCardHeight = _getHeight(0);
            final stackHeight = firstCardHeight;

            final currentHeight = stackHeight +
                (totalListHeight - stackHeight) * _expandAnimation.value;

            final List<Widget> stackItems = [];

            final maxStackOffset = widget.spacing * (visibleCount - 1);

            for (int i = 0; i < visibleCount; i++) {
              final listIndex = i;
              final stackIndex = visibleCount - 1 - i;

              final scale = 1.0 -
                  (widget.scaleFactor *
                      stackIndex *
                      (1 - _expandAnimation.value));
              final shadowOpacity = 1.0 - _expandAnimation.value;

              double stackPosition =
                  maxStackOffset - (widget.spacing * stackIndex);

              double listPosition = 0;
              for (int j = 0; j < listIndex; j++) {
                listPosition += _getHeight(j);
              }

              final currentPosition = stackPosition +
                  (listPosition - stackPosition) * _expandAnimation.value;

              stackItems.add(
                Positioned(
                  top: currentPosition,
                  left: 0,
                  right: 0,
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: Container(
                      key: _keys[i],
                      decoration: BoxDecoration(
                        boxShadow: shadowOpacity > 0
                            ? [
                                BoxShadow(
                                  color: Colors.black26
                                      .withOpacity(0.26 * shadowOpacity),
                                  blurRadius: 8,
                                  offset: const Offset(0, -8),
                                  spreadRadius: stackIndex == 0 ? 1 : 0,
                                ),
                              ]
                            : [],
                      ),
                      child: widget.children[i],
                    ),
                  ),
                ),
              );
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

class StackedCards extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final int maxVisibleCards;
  final Alignment alignment;
  final double scaleFactor;
  static const double _topShadowOffset = 8.0;
  static const double _shadowBlur = 8.0;
  static const double _baseCardHeight = 120.0;

  const StackedCards({
    super.key,
    required this.children,
    this.spacing = 15.0,
    this.maxVisibleCards = 3,
    this.alignment = Alignment.center,
    this.scaleFactor = 0.03,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount = min(children.length, maxVisibleCards);
    final stackHeight = _baseCardHeight + (spacing * (visibleCount - 1));
    final topPadding = _topShadowOffset + _shadowBlur;
    final totalHeight = stackHeight + topPadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        return _SizeResolver(
          children: children,
          builder: (context, size) {
            final visibleChildren = children.take(maxVisibleCards).toList();

            return Container(
              width: size.width,
              height: totalHeight,
              alignment: Alignment.topCenter,
              child: Stack(
                alignment: alignment,
                clipBehavior: Clip.none,
                children: List.generate(visibleChildren.length, (index) {
                  final scale = 1.0 -
                      (scaleFactor * (visibleChildren.length - 1 - index));
                  final isTopCard = index == 0;

                  return Positioned(
                    bottom: spacing * (visibleChildren.length - 1 - index),
                    left: 0,
                    right: 0,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: [
                            if (isTopCard)
                              const BoxShadow(
                                color: Colors.black26,
                                blurRadius: _shadowBlur,
                                offset: Offset(0, -8),
                                spreadRadius: 1,
                              )
                            else
                              const BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, -4),
                              ),
                          ],
                        ),
                        child: visibleChildren[index],
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        );
      },
    );
  }
}

class _SizeResolver extends StatefulWidget {
  final List<Widget> children;
  final Widget Function(BuildContext context, Size size) builder;

  const _SizeResolver({
    required this.children,
    required this.builder,
  });

  @override
  State<_SizeResolver> createState() => _SizeResolverState();
}

class _SizeResolverState extends State<_SizeResolver> {
  final GlobalKey _measuringKey = GlobalKey();
  Size? maxSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChildren();
    });
  }

  void _measureChildren() {
    final RenderBox? renderBox =
        _measuringKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      setState(() {
        maxSize = renderBox.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (maxSize == null) {
      return Opacity(
        opacity: 0,
        child: IntrinsicHeight(
          // Use IntrinsicHeight to wrap content tightly
          child: Column(
            key: _measuringKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.children.map((child) => ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: double.infinity),
                    child: child,
                  )),
            ],
          ),
        ),
      );
    }

    return widget.builder(context, maxSize!);
  }
}
