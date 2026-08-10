import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/kai_event.dart';
import 'events_view_model.dart';

class EatButton extends StatefulWidget {
  const EatButton({super.key, required this.event});

  final KaiEvent event;

  @override
  State<EatButton> createState() => _EatButtonState();
}

class _EatButtonState extends State<EatButton> {
  bool _isEating = false;

  Future<void> _eat() async {
    if (_isEating) return;

    setState(() {
      _isEating = true;
    });

    try {
      await context.read<EventsViewModel>().eat(widget.event.id);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update this event')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isEating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEat = widget.event.isActive && !_isEating;

    return ElevatedButton(
      onPressed: canEat ? _eat : null,
      child: _isEating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Eat'),
    );
  }
}
