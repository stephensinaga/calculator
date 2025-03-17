import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/history_model.dart';  // Pastikan file model sudah ada
import 'screens/calculator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inisialisasi Hive sebelum membuka box
  await Hive.initFlutter();

  // 🔥 Registrasi adapter jika diperlukan
  Hive.registerAdapter(HistoryModelAdapter());

  // 🔥 Buka box
  await Hive.openBox<HistoryModel>('history');
  runApp(const CalculatorApp());
}


class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorScreen(),
    );
  }
}
