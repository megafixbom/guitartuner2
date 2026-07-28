import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'views/tuner_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: GuitarTunerApp(),
    ),
  );
}

class GuitarTunerApp extends StatelessWidget {
  const GuitarTunerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guitar Tuner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B12),
        useMaterial3: true,
      ),
      home: const TunerScreen(),
    );
  }
}
