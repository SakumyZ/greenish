import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:greenish/services/timer_service.dart';
import 'package:greenish/services/windows_overlay_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimerService', () {
    late TimerService timer;

    setUp(() {
      timer = TimerService(
        usageIntervalSec: 10,
        restDurationSec: 5,
        snoozeDurationSec: 3,
        gracePeriodSec: 2,
        longBreakThresholdSec: 10,
      );
    });

    tearDown(() {
      timer.dispose();
    });

    test('starts in idle state', () {
      expect(timer.state, TimerState.idle);
      expect(timer.accumulatedSec, 0);
    });

    test('transitions to counting on start', () {
      timer.start();
      expect(timer.state, TimerState.counting);
    });

    test('transitions to idle on pause', () {
      timer.start();
      timer.pause();
      expect(timer.state, TimerState.idle);
    });

    test('reset zeroes accumulated and goes idle', () {
      timer.start();
      timer.reset();
      expect(timer.state, TimerState.idle);
      expect(timer.accumulatedSec, 0);
    });

    test('restNow triggers resting state', () {
      timer.start();
      timer.restNow();
      expect(timer.state, TimerState.resting);
      expect(timer.restRemainingSec, 5);
    });

    test('skip ends rest and resets accumulated', () {
      timer.start();
      timer.restNow();
      timer.skip();
      expect(timer.state, TimerState.counting);
      expect(timer.accumulatedSec, 0);
    });

    test('snooze transitions to snoozed state', () {
      timer.start();
      timer.restNow();
      timer.snooze();
      expect(timer.state, TimerState.snoozed);
    });

    test('progress calculation', () {
      expect(timer.progress, 0.0);
    });
  });

  group('WindowsOverlayService', () {
    late WindowsOverlayService service;

    setUp(() {
      service = WindowsOverlayService();
    });

    test('snooze action clears visible state before callback', () {
      var callbackSawClosedOverlay = false;
      service.debugSetOverlayVisible(true);
      service.onSnooze = () {
        callbackSawClosedOverlay = !service.isOverlayVisible;
      };

      service.handleOverlayAction('snooze');

      expect(service.isOverlayVisible, isFalse);
      expect(callbackSawClosedOverlay, isTrue);
    });

    test('done action clears visible state without invoking callbacks', () {
      var snoozeCalled = false;
      var skipCalled = false;
      service.debugSetOverlayVisible(true);
      service.onSnooze = () => snoozeCalled = true;
      service.onSkip = () => skipCalled = true;

      service.handleOverlayAction('done');

      expect(service.isOverlayVisible, isFalse);
      expect(snoozeCalled, isFalse);
      expect(skipCalled, isFalse);
    });

    test('computes overlay frame inside current monitor work area', () {
      final frame = service.computeOverlayFrame(
        const Rect.fromLTWH(1920, 0, 2560, 1400),
        scaleFactor: 1.5,
        overlaySize: const Size(320, 220),
        margin: 8,
      );

      expect(frame.left, 1920 + 2560 - 320 * 1.5 - 8 * 1.5);
      expect(frame.top, 1400 - 220 * 1.5 - 8 * 1.5);
      expect(frame.width, 320 * 1.5);
      expect(frame.height, 220 * 1.5);
    });
  });
}
