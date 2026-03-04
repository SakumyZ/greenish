import 'package:flutter_test/flutter_test.dart';
import 'package:greenish/services/timer_service.dart';

void main() {
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
}
