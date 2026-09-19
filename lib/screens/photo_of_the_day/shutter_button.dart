import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 84 × 84 shutter: a 3 px ring with a 66 × 66 orange disc inside.
/// Shrinks to 94% while pressed.
class ShutterButton extends StatefulWidget {
  const ShutterButton({super.key, required this.onPressed});

  /// Null disables the button (drawn at 40% opacity).
  final VoidCallback? onPressed;

  @override
  State<ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<ShutterButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed != null) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: 'Take photo',
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: Opacity(
          opacity: widget.onPressed == null ? 0.4 : 1,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.text, width: 3),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
