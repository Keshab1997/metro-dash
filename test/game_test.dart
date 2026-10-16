import 'package:dog_road_runner/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the playable title screen and accepts a tap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const DogRoadRunnerApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CustomPaint), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Puppy Dash')), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CustomPaint), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
