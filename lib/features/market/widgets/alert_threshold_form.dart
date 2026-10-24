import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class AlertThresholdForm extends StatelessWidget {
  const AlertThresholdForm({
    required this.upperController,
    required this.lowerController,
    required this.onSave,
    required this.upperLimit,
    required this.lowerLimit,
    super.key,
  });

  final TextEditingController upperController;
  final TextEditingController lowerController;
  final VoidCallback onSave;
  final double upperLimit;
  final double lowerLimit;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Limites de alerta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: upperController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'UP',
                    prefixIcon: Icon(Icons.trending_up),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: lowerController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'DOWN',
                    prefixIcon: Icon(Icons.trending_down),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvar limites'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ativo: UP ${upperLimit > 0 ? upperLimit.toStringAsFixed(2) : '—'} · '
            'DOWN ${lowerLimit > 0 ? lowerLimit.toStringAsFixed(2) : '—'}',
            style: const TextStyle(color: appTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
