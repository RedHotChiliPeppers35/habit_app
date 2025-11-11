import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/features/onboarding/questionnaire_screen.dart';

class QuestionnaireButton extends ConsumerWidget {
  final String label;
  const QuestionnaireButton({
    Key? key,
    this.label = 'Take the personalization test',
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final result = await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const QuestionnaireScreen()));
        // result == true indicates the questionnaire was submitted and saved
        if (result == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Questionnaire saved.')));
        }
      },
      child: Text(label),
    );
  }
}
