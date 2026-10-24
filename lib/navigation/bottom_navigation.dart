import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/analyst/analyst_screen.dart';
import '../features/market/market_screen.dart';

class BottomNavigationShell extends StatefulWidget {
  const BottomNavigationShell({super.key});

  @override
  State<BottomNavigationShell> createState() => _BottomNavigationShellState();
}

class _BottomNavigationShellState extends State<BottomNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const MarketScreen(),
      const AlertsScreen(),
      const AnalystScreen(),
    ];

    final labels = ['Mercado', 'Alertas', 'Analista IA'];
    final icons = [
      Icons.bar_chart_rounded,
      Icons.notifications_active_rounded,
      Icons.smart_toy_rounded,
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: List.generate(
          labels.length,
          (index) => NavigationDestination(
            icon: Icon(icons[index]),
            label: labels[index],
          ),
        ),
        backgroundColor: appSurface,
        indicatorColor: appAccentStart.withValues(alpha: 0.18),
      ),
    );
  }
}
