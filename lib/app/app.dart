import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../navigation/bottom_navigation.dart';

class BitcoinMonitorApp extends StatelessWidget {
  const BitcoinMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bitcoin Monitor AI',
      theme: appTheme,
      home: const BottomNavigationShell(),
    );
  }
}
