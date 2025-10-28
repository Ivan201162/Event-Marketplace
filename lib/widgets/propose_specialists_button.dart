import 'package:event_marketplace_app/screens/specialist_selection_screen.dart';
import 'package:flutter/material.dart';

class ProposeSpecialistsButton extends StatelessWidget {
  const ProposeSpecialistsButton({
    required this.customerId, required this.eventId, super.key,
    this.message,
  });
  final String customerId;
  final String eventId;
  final String? message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ElevatedButton.icon(
          onPressed: () => _showSpecialistSelection(context),
          icon: const Icon(Icons.people_alt),
          label: const Text('Предложить специалистов'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        ),
      );

  void _showSpecialistSelection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SpecialistSelectionScreen(
            customerId: customerId, eventId: eventId, message: message,),
      ),
    );
  }
}
