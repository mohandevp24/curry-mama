import 'package:flutter/material.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(const CurryMamaAdminApp());
}

class CurryMamaAdminApp extends StatelessWidget {
  const CurryMamaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Curry Mama - Premium Meat Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00C853),
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00C853),
          secondary: Colors.white,
          background: Color(0xFF0F0F12),
          surface: Color(0xFF16161E),
          onPrimary: Colors.black,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white70,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}
