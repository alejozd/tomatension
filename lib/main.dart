import 'package:flutter/material.dart';
import 'pages/bienvenidos_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  // Ensure Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check if the platform is not Android or iOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Initialize FFI for desktop platforms
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TomaTension',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BienvenidosPage(),
    );
  }
}
