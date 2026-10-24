import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({required this.summary, super.key});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do mercado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            summary,
            style: const TextStyle(color: appTextSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
