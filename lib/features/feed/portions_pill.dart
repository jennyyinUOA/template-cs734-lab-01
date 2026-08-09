import 'package:flutter/material.dart';
import '../../data/models/kai_event.dart';

class PortionsPill extends StatelessWidget {
  const PortionsPill({super.key, required this.event});

  final KaiEvent event;

  @override
  Widget build(BuildContext context) {
    String label;
    Color backgroundColor;

    if (!event.isActive) {
      label = 'Gone';
      backgroundColor = Colors.grey;
    } else if (event.portionsLeft > 10) {
      label = 'Plenty';
      backgroundColor = Colors.green;
    } else if (event.portionsLeft >= 3) {
      label = 'Going fast';
      backgroundColor = Colors.amber;
    } else {
      label = 'Almost gone';
      backgroundColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text('$label (${event.portionsLeft})'),
    );
  }
}
