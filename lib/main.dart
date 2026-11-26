
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Hive
  await Hive.initFlutter();

  // Abre as caixas utilizadas pelo chatbot
  await Hive.openBox<dynamic>('btc_chat_messages');
  await Hive.openBox<dynamic>('btc_chat_metadata');
  await Hive.openBox<dynamic>('btc_ai_health_events');

  // Inicializa o aplicativo com Riverpod
  runApp(
    const ProviderScope(
      child: BitcoinMonitorApp(),
    ),
  );
}
