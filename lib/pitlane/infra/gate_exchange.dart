import 'dart:convert';

import '../config/pitwall_config.dart';
import '../core/race_models.dart';
import 'garage_vault.dart';
import 'paddock_attribution.dart';
import 'track_agent.dart';

class GateExchange {
  GateExchange(this._agent, this._vault);

  final TrackAgent _agent;
  final GarageVault _vault;

  Future<GateReply> request(Map<String, dynamic> payload) async {
    if (!PitwallConfig.grayCredentialsReady) {
      return GateReply.rejected('credentials_unavailable');
    }
    try {
      pitTrace(() => '[NSW.GATE] request ${jsonEncode(payload)}');
      final response = await _agent
          .post(
            Uri.parse(PitwallConfig.endpoint),
            headers: const <String, String>{
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      pitTrace(
        () => '[NSW.GATE] response ${response.statusCode} ${response.body}',
      );
      if (response.statusCode != 200) {
        return GateReply.rejected('http_${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return GateReply.rejected('invalid_response');
      final reply = GateReply.fromJson(Map<String, dynamic>.from(decoded));
      if (reply.hasDestination) {
        await _vault.cacheUrl(reply.url!, reply.expiresAt);
      }
      return reply;
    } catch (error) {
      pitTrace(() => '[NSW.GATE] failed: $error');
      return GateReply.rejected('network_failure');
    }
  }
}
