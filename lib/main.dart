// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/map_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FMTC backend and store only on mobile platforms (skip Windows/macOS/Linux)
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    await FMTCObjectBoxBackend().initialise();
    await FMTCStore('SafeRouteCache').manage.create();
    debugPrint('✅ FMTC tile caching initialized');
  } else {
    debugPrint('ℹ️ FMTC tile caching skipped for desktop');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoute',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapScreen(),
    );
  }
}
