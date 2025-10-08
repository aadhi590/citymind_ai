import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart'; // adjust if your app name differs

void main() {
  testWidgets('Splash screen shows Kannada text',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CityMindApp());

    // Splash screen text check
    expect(find.text('ನಮ್ಮ ಬೆಂಗಳೂರುಗಾಗಿ'), findsOneWidget);
  });

  testWidgets('Main screen has bottom navigation with 5 tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));

    // Check navigation items exist
    expect(find.text("Feed"), findsOneWidget);
    expect(find.text("Civic"), findsOneWidget);
    expect(find.text("Environment"), findsOneWidget);
    expect(find.text("Sentiment"), findsOneWidget);
    expect(find.text("More"), findsOneWidget);
  });
}
