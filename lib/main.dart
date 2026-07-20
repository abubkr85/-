import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const HeadGestureApp());
}

class HeadGestureApp extends StatelessWidget {
  const HeadGestureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'التحكم بإيماءات الرأس',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const HomeScreen(),
    );
  }
}
