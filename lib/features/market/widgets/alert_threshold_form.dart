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
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: appAccentEnd,
                size: 23,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Limites de alerta',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              final stackFields = constraints.maxWidth < 460;

              final upperField = _buildField(
                controller: upperController,
                label: 'UP',
                icon: Icons.trending_up_rounded,
              );

              final lowerField = _buildField(
                controller: lowerController,
                label: 'DOWN',
                icon: Icons.trending_down_rounded,
              );

              if (stackFields) {
                return Column(
                  children: [
                    upperField,
                    const SizedBox(height: 15),
                    lowerField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: upperField),
                  const SizedBox(width: 14),
                  Expanded(child: lowerField),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // BOTÃO
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Salvar limites'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                backgroundColor: appAccentEnd,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // RESUMO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: appBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIMITES ATIVOS',
                  style: TextStyle(
                    color: appTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: appSuccess,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'UP',
                      style: TextStyle(
                        color: appTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        upperLimit > 0
                            ? upperLimit.toStringAsFixed(2)
                            : '—',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.trending_down_rounded,
                      color: appDanger,
                      size: 17,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'DOWN',
                      style: TextStyle(
                        color: appTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        lowerLimit > 0
                            ? lowerLimit.toStringAsFixed(2)
                            : '—',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      maxLines: 1,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: appBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: appBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: appAccentEnd,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}