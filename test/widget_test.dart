import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitor_btc_ai/app/app.dart';

void main() {
  testWidgets('Bitcoin Monitor app loads market screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BitcoinMonitorApp()));
    await tester.pumpAndSettle();

    expect(find.text('Bitcoin Monitor'), findsOneWidget);
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Alertas'), findsOneWidget);
    expect(find.text('Analista IA'), findsOneWidget);
  });
}
