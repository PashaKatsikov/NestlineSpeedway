enum LaneMode {
  native,
  portal,
  undecided;

  String get storageValue => switch (this) {
    LaneMode.native => 'native',
    LaneMode.portal => 'portal',
    LaneMode.undecided => 'undecided',
  };

  static LaneMode parse(String? value) => switch (value) {
    'portal' => LaneMode.portal,
    'native' => LaneMode.native,
    _ => LaneMode.undecided,
  };
}

class GateReply {
  const GateReply({
    required this.accepted,
    this.url,
    this.expiresAt,
    this.reason,
  });

  factory GateReply.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expires'];
    return GateReply(
      accepted: json['ok'] == true,
      url: json['url'] is String ? json['url'] as String : null,
      expiresAt: rawExpiry is num
          ? rawExpiry.toInt()
          : int.tryParse(rawExpiry?.toString() ?? ''),
      reason: json['message']?.toString(),
    );
  }

  factory GateReply.rejected(String reason) =>
      GateReply(accepted: false, reason: reason);

  final bool accepted;
  final String? url;
  final int? expiresAt;
  final String? reason;

  bool get hasDestination => accepted && (url?.isNotEmpty ?? false);
}

sealed class RouteOutcome {
  const RouteOutcome();
}

final class NativeLane extends RouteOutcome {
  const NativeLane();
}

final class PortalLane extends RouteOutcome {
  const PortalLane(this.url, {this.coldLaunch = false});

  final String url;
  final bool coldLaunch;
}

final class OfflineLane extends RouteOutcome {
  const OfflineLane({required this.returnToNative});

  final bool returnToNative;
}
