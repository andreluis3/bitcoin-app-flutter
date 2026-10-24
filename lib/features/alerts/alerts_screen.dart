import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models/market_alert.dart';
import '../../services/alert_service.dart';
import '../../data/repositories/bitcoin_repository.dart';
import 'widgets/alert_history_tile.dart';

final alertsProvider = FutureProvider<List<MarketAlert>>((ref) {
  final alertService = AlertService(BitcoinRepository());
  return alertService.getAlertHistory();
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Histórico de alertas',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
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
                'Dados demonstrativos do histórico de eventos.',
                style: TextStyle(color: appTextSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: alertsAsync.when(
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      return const Center(
                        child: Text('Nenhum alerta registrado no momento.'),
                      );
                    }

                    return ListView.separated(
                      itemCount: alerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return AlertHistoryTile(alert: alerts[index]);
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => const Center(
                    child: Text(
                      'Não foi possível carregar o histórico de alertas.',
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
