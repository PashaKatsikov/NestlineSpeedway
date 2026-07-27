import 'dart:async';
import 'dart:io';

import 'config/pitwall_config.dart';
import 'core/race_models.dart';
import 'infra/gate_exchange.dart';
import 'infra/garage_vault.dart';
import 'infra/launch_lane_reader.dart';
import 'infra/paddock_attribution.dart';
import 'infra/pulse_hub.dart';
import 'infra/signal_probe.dart';
import 'infra/track_agent.dart';

class RaceCoordinator {
  RaceCoordinator({
    required this.vault,
    required this.probe,
    required this.attribution,
    required this.exchange,
    required this.notifications,
    required this.agent,
    required this.runtimeEnabled,
  });

  final GarageVault vault;
  final SignalProbe probe;
  final PaddockAttribution attribution;
  final GateExchange exchange;
  final PulseHub notifications;
  final TrackAgent agent;
  final bool runtimeEnabled;

  bool get enabled => runtimeEnabled && PitwallConfig.grayCredentialsReady;

  Future<RouteOutcome>? _decideFuture;

  /// De-duplicates only *concurrent* calls, then clears the cache so a later
  /// Retry (e.g. from the offline screen once Wi-Fi returns) re-runs the whole
  /// pipeline instead of replaying a cached OfflineLane forever.
  Future<RouteOutcome> decide({
    required void Function(double value) onProgress,
  }) =>
      _decideFuture ??= _decide(onProgress: onProgress)
          .whenComplete(() => _decideFuture = null);

  Future<RouteOutcome> _decide({
    required void Function(double value) onProgress,
  }) async {
    if (!enabled) {
      pitTrace(
        () => '[NSW.RACE] gate disabled '
            'runtime=$runtimeEnabled creds=${PitwallConfig.grayCredentialsReady}',
      );
      onProgress(1);
      return const NativeLane();
    }

    pitTrace(() => '[NSW.RACE] decide start lane=${vault.lane}');

    notifications.onTokenChanged = _refreshForToken;
    final coldLane = await LaunchLaneReader.consume();
    if (coldLane != null) {
      await vault.saveLane(LaneMode.portal);
      await vault.consumePushUrl();
      unawaited(_backgroundDispatch());
      onProgress(1);
      return PortalLane(coldLane, coldLaunch: true);
    }

    onProgress(0.12);
    return switch (vault.lane) {
      LaneMode.undecided => _firstDecision(onProgress),
      LaneMode.portal => _returningPortal(onProgress),
      LaneMode.native => _returningNative(onProgress),
    };
  }

  Future<RouteOutcome> _firstDecision(void Function(double) progress) async {
    if (!await probe.hasInterface()) {
      pitTrace(() => '[NSW.RACE] first: no interface → offline');
      return const OfflineLane(returnToNative: false);
    }
    progress(0.28);
    try {
      await notifications.boot();
    } catch (_) {}
    if (!await probe.canReachNetwork()) {
      pitTrace(() => '[NSW.RACE] first: DNS probe failed → offline');
      return const OfflineLane(returnToNative: false);
    }
    progress(0.48);
    await attribution.awaitSignals();
    progress(0.72);
    final reply = await _requestConfig();
    progress(1);
    pitTrace(
      () => '[NSW.RACE] first: config hasDest=${reply.hasDestination} '
          'url=${reply.url}',
    );
    if (reply.hasDestination) {
      await vault.saveLane(LaneMode.portal);
      return PortalLane(reply.url!);
    }
    await vault.saveLane(LaneMode.native);
    return const NativeLane();
  }

  Future<RouteOutcome> _returningPortal(void Function(double) progress) async {
    if (!await probe.hasInterface()) {
      return const OfflineLane(returnToNative: false);
    }
    final pending = await vault.consumePushUrl();
    if (pending != null && pending.isNotEmpty) {
      progress(1);
      return PortalLane(pending);
    }
    final cached = await vault.savedUrl();
    if (cached != null && !vault.cachedUrlExpired) {
      progress(1);
      return PortalLane(cached);
    }

    await Future.wait<void>(<Future<void>>[
      notifications.boot(),
      attribution.start(),
    ]);
    if (!await probe.canReachNetwork()) {
      return const OfflineLane(returnToNative: false);
    }
    progress(0.62);
    await attribution.awaitSignals(installTimeout: const Duration(seconds: 5));
    final reply = await _requestConfig();
    progress(1);
    if (reply.hasDestination) return PortalLane(reply.url!);
    if (cached != null) return PortalLane(cached);
    return const OfflineLane(returnToNative: false);
  }

  Future<RouteOutcome> _returningNative(void Function(double) progress) async {
    if (!await probe.hasInterface()) {
      progress(1);
      return const NativeLane();
    }
    await Future.wait<void>(<Future<void>>[
      notifications.boot(),
      attribution.start(),
    ]);
    if (!await probe.canReachNetwork()) {
      progress(1);
      return const NativeLane();
    }
    progress(0.55);
    await attribution.awaitSignals();
    final reply = await _requestConfig();
    progress(1);
    if (!reply.hasDestination) return const NativeLane();
    await vault.saveLane(LaneMode.portal);
    return PortalLane(reply.url!);
  }

  Future<GateReply> _requestConfig({String? token}) async {
    final body = await attribution.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: token ?? notifications.token,
    );
    return exchange.request(body);
  }

  Future<void> _backgroundDispatch() async {
    try {
      await Future.wait<void>(<Future<void>>[
        notifications.boot(),
        attribution.awaitSignals(),
      ]);
      await _requestConfig();
    } catch (_) {}
  }

  Future<void> _refreshForToken(String token) async {
    try {
      await _requestConfig(token: token);
    } catch (_) {}
  }
}
