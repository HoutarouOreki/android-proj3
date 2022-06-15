import 'package:flutter/material.dart';

class FullWidthButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final Widget? child;

  final Color? primary;

  const FullWidthButton(
      {Key? key, required this.child, required this.onPressed, this.primary})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: primary,
          minimumSize: const Size.fromHeight(50),
          textStyle: const TextStyle(fontSize: 20),
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
