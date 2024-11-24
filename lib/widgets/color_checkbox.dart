import 'package:flutter/material.dart';

enum ColorCheckboxVariant { check, color }

class ColorCheckbox extends StatelessWidget {
  final Color color;
  final bool checked;
  final Function()? onChanged;
  final ColorCheckboxVariant variant;
  final double size;
  final double progress;
  final double strokeWidth;
  final IconData checkIcon;

  const ColorCheckbox({
    super.key,
    required this.color,
    required this.checked,
    this.onChanged,
    this.variant = ColorCheckboxVariant.check,
    this.size = 32.0,
    this.progress = 0.0,
    this.strokeWidth = 2.0,
    this.checkIcon = Icons.check,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      customBorder: const CircleBorder(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: checked
              ? variant == ColorCheckboxVariant.check
                  ? color.withOpacity(0.5)
                  : color
              : variant == ColorCheckboxVariant.check
                  ? color
                  : color.withOpacity(0.0),
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: checked
                    ? variant == ColorCheckboxVariant.check
                        ? color.withOpacity(0.5)
                        : color
                    : variant == ColorCheckboxVariant.check
                        ? color
                        : color.withOpacity(0.0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white38,
                  width: strokeWidth,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(1.0),
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: strokeWidth,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(194, 255, 255, 255)),
                strokeCap: StrokeCap.round,
              ),
            ),
            if (checked && variant == ColorCheckboxVariant.check)
              Center(
                child: Icon(
                  checkIcon,
                  color: Colors.white,
                  size: size * 0.6,
                ),
              ),
          ],
        ), // Show icon for checked state
      ),
    );
  }
}
