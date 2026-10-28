import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models/market_alert.dart';
import '../../services/alert_service.dart';
import 'widgets/alert_history_tile.dart';

final alertsProvider = FutureProvider<List<MarketAlert>>((ref) async {
  return ref.watch(alertServiceProvider).getAlertHistory();
});

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: appBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Histórico de alertas',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar histórico',
                    onPressed: () => ref.invalidate(alertsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: appSurface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: appBorder),
                    ),
                    child: Text(
                      '${alertsAsync.value?.length ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Eventos reais registrados quando o preço cruza um limite.',
                style: TextStyle(color: appTextSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: alertsAsync.when(
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      return const Center(
                        child: Text('Nenhum alerta real registrado ainda.'),
                      );
                    }
                    return ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          AlertHistoryTile(alert: alerts[index]),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Não foi possível carregar o histórico.'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(alertsProvider),
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
