import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Gestion des Tâches',
      theme: themeProvider.isDarkMode
          ? ThemeData.dark() // Thème sombre
          : ThemeData.light(), // Thème clair
      home: const HomeScreen(),
    );
  }
}
