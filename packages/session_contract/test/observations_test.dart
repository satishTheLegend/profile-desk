import 'package:flutter_test/flutter_test.dart';
import 'package:session_contract/session_contract.dart';

import 'support/fake_engine.dart';

void main() {
  test(
    'network observations never reveal content or imply authentication',
    () async {
      final engine = FakeSessionEngine()..locked = true;
      final coordinator = SessionCoordinator(engine);
      addTearDown(coordinator.dispose);
      await coordinator.initialize();
      for (final network in NetworkObservation.values) {
        engine.emit(
          EngineEvent(kind: EngineEventKind.networkChanged, network: network),
        );
        expect(coordinator.state.network, network);
        expect(coordinator.state.locked, isTrue);
        expect(coordinator.state.covered, isTrue);
        expect(coordinator.state.selectedProfileId, isNull);
      }
      expect(engine.calls.where((c) => c.startsWith('open')), isEmpty);
    },
  );
  test(
    'progress belongs to the exact current view and clears after cancellation',
    () async {
      final engine = FakeSessionEngine();
      engine.seed('a');
      engine.seed('b');
      final coordinator = SessionCoordinator(engine);
      addTearDown(coordinator.dispose);
      await coordinator.initialize();
      await coordinator.select('a');
      final a = coordinator.state.view!;
      engine.emit(
        EngineEvent(
          kind: EngineEventKind.transferChanged,
          view: a,
          transferActive: true,
          progress: .25,
        ),
      );
      expect(coordinator.state.transferProgress, .25);
      engine.emit(
        EngineEvent(
          kind: EngineEventKind.transferChanged,
          view: a,
          transferActive: false,
        ),
      );
      expect(coordinator.state.transferProgress, isNull);
      await coordinator.select('b');
      engine.emit(
        EngineEvent(
          kind: EngineEventKind.transferChanged,
          view: a,
          transferActive: true,
          progress: .9,
        ),
      );
      expect(coordinator.state.transferActive, isFalse);
      expect(coordinator.state.transferProgress, isNull);
      final b = coordinator.state.view!;
      engine.emit(
        EngineEvent(
          kind: EngineEventKind.transferChanged,
          view: b,
          transferActive: true,
          progress: double.nan,
        ),
      );
      expect(coordinator.state.transferProgress, isNull);
    },
  );
}
