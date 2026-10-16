import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:metro_dash/main.dart';

/// Advance game time in realistic frames: the game clamps dt at 50 ms, so one
/// giant pump would only advance it by one tick.
Future<void> advance(WidgetTester tester, double seconds,
    {Duration step = const Duration(milliseconds: 33)}) async {
  final steps = (seconds * 1000 / step.inMilliseconds).ceil();
  for (var i = 0; i < steps; i++) {
    await tester.pump(step);
  }
}

void main() {
  testWidgets('boots to the title screen and starts a run',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MetroDashApp());
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('METRO DASH'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.tap(find.text('PLAY'));
    await tester.pump(const Duration(milliseconds: 33));
    expect(find.text('3'), findsOneWidget);

    await advance(tester, 3.6);
    expect(find.text('PLAY'), findsNothing);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('COINS'), findsOneWidget);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('swipes and keys never throw while running',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MetroDashApp());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('PLAY'));
    await advance(tester, 3.6);

    for (final Offset drag in const <Offset>[
      Offset(-120, 0),
      Offset(120, 0),
      Offset(0, -140),
      Offset(0, 140),
    ]) {
      await tester.dragFrom(const Offset(207, 700), drag);
      await advance(tester, 0.3);
    }
    await advance(tester, 6);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('running into an obstacle ends the run and RETRY restarts it',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(414, 896);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const MetroDashApp());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('PLAY'));
    await advance(tester, 3.6);

    // Run straight, no input: the fixed spawn seed guarantees a crash.
    var over = false;
    for (var i = 0; i < 90 && !over; i++) {
      await advance(tester, 1.0);
      over = find.text('RETRY').evaluate().isNotEmpty;
    }
    expect(over, isTrue, reason: 'the run should have ended within 90 s');
    expect(find.text('NICE RUN!'), findsOneWidget);

    await tester.tap(find.text('RETRY'));
    await advance(tester, 0.4);
    expect(find.text('RETRY'), findsNothing);
    expect(find.text('PLAY'), findsNothing);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
