import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fairride/fare_ride_screens.dart';

void main() {
  testWidgets('rider can navigate from landing to fare split', (tester) async {
    await tester.pumpWidget(const FareRideApp());

    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '5551234567');
    await tester.ensureVisible(find.text('Continue as Rider'));
    await tester.tap(find.text('Continue as Rider'));
    await tester.pumpAndSettle();
    expect(find.text('Where are you headed?'), findsOneWidget);

    await tester.ensureVisible(find.text('Find a ride'));
    await tester.tap(find.text('Find a ride'));
    await tester.pumpAndSettle();
    expect(find.text('Available rides'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'North Campus');
    await tester.enterText(find.byType(TextFormField).at(1), 'City Center');
    await tester.ensureVisible(find.text('Request this ride'));
    await tester.tap(find.text('Request this ride'));
    await tester.pumpAndSettle();
    expect(find.text('Everyone pays less.'), findsOneWidget);
  });

  testWidgets('driver can navigate through posting and pickup details', (
    tester,
  ) async {
    await tester.pumpWidget(const FareRideApp());

    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '5551234567');
    await tester.ensureVisible(find.text('Driver'));
    await tester.tap(find.text('Driver'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as Driver'), findsOneWidget);
    await tester.ensureVisible(find.text('Continue as Driver'));
    await tester.tap(find.text('Continue as Driver'));
    await tester.pumpAndSettle();
    expect(find.text('A few details first'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Taylor Driver');
    await tester.enterText(find.byType(TextFormField).at(1), 'City Car');
    await tester.tap(find.text('Driver’s license'));
    await tester.tap(find.text('Vehicle registration'));
    await tester.ensureVisible(find.text('Save and continue'));
    await tester.ensureVisible(find.text('Save and continue'));
    await tester.tap(find.text('Save and continue'));
    await tester.pumpAndSettle();
    expect(find.text('Share your journey'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'North Campus');
    await tester.enterText(find.byType(TextFormField).at(1), 'City Center');
    await tester.enterText(find.byType(TextFormField).at(2), '8.50');
    await tester.ensureVisible(find.text('Continue to pickup details'));
    await tester.tap(find.text('Continue to pickup details'));
    await tester.pumpAndSettle();
    expect(find.text('Set the pickup order'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Main Gate');
    await tester.ensureVisible(find.text('Confirm ride'));
    await tester.tap(find.text('Confirm ride'));
    await tester.pumpAndSettle();
    expect(find.text('Everyone pays less.'), findsOneWidget);
  });
}
