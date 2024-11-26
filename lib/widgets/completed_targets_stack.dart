import 'package:flutter/material.dart';
import 'package:targetly/models/target.dart';
import 'package:targetly/widgets/target.dart';

class CompletedTargetsStack extends StatefulWidget {
  final List<Target> completedTargets;
  final Function(Target) onTargetRemoved;

  const CompletedTargetsStack({
    super.key,
    required this.completedTargets,
    required this.onTargetRemoved,
  });

  @override
  State<CompletedTargetsStack> createState() => _CompletedTargetsStackState();
}

class _CompletedTargetsStackState extends State<CompletedTargetsStack> {
  bool _isExpanded = false;
  static const double itemHeight = 121.0;
  static const double stackHeight = 100.0;
  static const double verticalPadding = 0.0;
  late double _maxHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maxHeight = MediaQuery.of(context).size.height * 0.4;
  }

  double get expandedHeight => _isExpanded
      ? (widget.completedTargets.length * (itemHeight + 2 * verticalPadding))
          .clamp(0.0, _maxHeight)
      : stackHeight;

  void _handleDismiss(Target target) {
    if (mounted) {
      widget.onTargetRemoved(target);
    }
  }

  void _handleTap() {
    if (mounted) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.completedTargets.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: expandedHeight,
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleTap,
          child: _isExpanded ? _buildExpandedList() : _buildStack(),
        ),
      ),
    );
  }

  Widget _buildStack() {
    if (widget.completedTargets.isEmpty) return const SizedBox.shrink();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: List.generate(
        widget.completedTargets.length.clamp(0, 3),
        (index) {
          if (index >= widget.completedTargets.length)
            return const SizedBox.shrink();

          final offsetY = -index * 10.0;
          final scale = 1.0 - (index * 0.05);

          return Positioned(
            top: offsetY,
            left: 0,
            right: 0,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: itemHeight,
                child: Dismissible(
                  key: ValueKey('stack_${widget.completedTargets[index].id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) =>
                      _handleDismiss(widget.completedTargets[index]),
                  child: TargetWidget(widget.completedTargets[index]),
                ),
              ),
            ),
          );
        },
      ).reversed.toList(),
    );
  }

  Widget _buildExpandedList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: widget.completedTargets.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final target = widget.completedTargets[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: verticalPadding),
          child: SizedBox(
            height: itemHeight,
            child: Dismissible(
              key: ValueKey('list_${target.id}'),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _handleDismiss(target),
              child: TargetWidget(target),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
