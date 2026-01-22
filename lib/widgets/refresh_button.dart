import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/services/audio_service.dart';

class RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;

  const RefreshButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: () {
        AudioService.playClickSound();
        onPressed();
      },
    );
  }
}
