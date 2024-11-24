import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  final String label;
  final EdgeInsets? margin;
  Color? bgColor;
  Color? borderColor;

  Tag({
    super.key,
    required this.label,
    this.margin,
    this.bgColor,
    this.borderColor,
  }) {
    bgColor = bgColor ?? Colors.grey[950];
    borderColor = borderColor ?? Colors.grey[850];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor!),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
