import 'package:flutter/material.dart';

import '../listening_practice/listening_practice_screen.dart';

class SpeakingPracticeScreen extends StatelessWidget {
  const SpeakingPracticeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ListeningPracticeScreen(speakingMode: true);
}
