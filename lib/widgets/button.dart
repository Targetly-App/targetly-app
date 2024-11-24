import 'package:flutter/material.dart';

enum ButtonVariant {
  primary,
  secondary,
  danger,
}

class Button extends StatelessWidget {
  final String text;
  final Function()? onPressed;
  final bool isLoading;
  final ButtonVariant variant;

  const Button({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = ButtonVariant.primary,
  });

  @override
  Widget build(BuildContext context) {
    Map<ButtonVariant, Color> colors = {
      ButtonVariant.primary: Theme.of(context).primaryColor,
      ButtonVariant.secondary:
          Theme.of(context).colorScheme.secondary.withOpacity(0.9),
      ButtonVariant.danger: Theme.of(context).colorScheme.error,
    };

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50.0),
        backgroundColor: colors[variant],
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(),
            )
          : Text(
              text,
              style: TextStyle(
                color: variant == ButtonVariant.primary
                    ? Colors.white
                    : Colors.black,
              ),
            ),
    );
  }
}
