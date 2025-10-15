import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_app/screens/map_screen.dart';
// FIX: Added the import for the flutter_map package
import 'package:flutter_map/flutter_map.dart';

void main() {
  testWidgets('MapScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MapScreen()));

    // Check AppBar title
    expect(find.text('SafeRoute Map'), findsOneWidget);

    // Check if map exists
    expect(find.byType(FlutterMap), findsOneWidget);
  });
}
