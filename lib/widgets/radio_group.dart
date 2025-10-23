import 'package:flutter/material.dart';

/// A custom radio group widget that manages a group of radio buttons
class RadioGroup<T> extends StatelessWidget {
  const RadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
  });

  final T value;
  final ValueChanged<T?> onChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children,
    );
  }
}



