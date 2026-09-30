import 'dart:convert';

sealed class SignalMessage {
  const SignalMessage();
}

class OfferMessage extends SignalMessage {
  final String sdp;
  final String? pairCode;
  const OfferMessage(this.sdp, {this.pairCode});
}

class AnswerMessage extends SignalMessage {
  final String sdp;
  const AnswerMessage(this.sdp);
}

class IceMessage extends SignalMessage {
  final String candidate;
  final String? sdpMid;
  final int sdpMLineIndex;
  const IceMessage(this.candidate, this.sdpMid, this.sdpMLineIndex);
}

class ControlMessage extends SignalMessage {
  final String action;
  final dynamic value;
  const ControlMessage(this.action, this.value);
}

class UnknownMessage extends SignalMessage {
  final String type;
  const UnknownMessage(this.type);
}

SignalMessage? decodeSignal(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    switch (decoded['type']) {
      case 'offer':
        final sdp = decoded['sdp'];
        return sdp is String
            ? OfferMessage(sdp, pairCode: decoded['pairCode'] as String?)
            : null;
      case 'answer':
        final sdp = decoded['sdp'];
        return sdp is String ? AnswerMessage(sdp) : null;
      case 'ice':
        final c = decoded['candidate'];
        if (c is String) {
          return IceMessage(
            c,
            decoded['sdpMid'] as String?,
            (decoded['sdpMLineIndex'] as num?)?.toInt() ?? 0,
          );
        }
        if (c is Map) {
          return IceMessage(
            c['candidate'] as String? ?? '',
            c['sdpMid'] as String?,
            (c['sdpMLineIndex'] as num?)?.toInt() ?? 0,
          );
        }
        return null;
      case 'control':
        return ControlMessage(
          (decoded['action'] as String?) ?? '',
          decoded['value'],
        );
      default:
        return UnknownMessage('${decoded['type']}');
    }
  } catch (_) {
    return null;
  }
}

String encodeAnswer(String sdp) => jsonEncode({'type': 'answer', 'sdp': sdp});

String encodeIce(String candidate, String? sdpMid, int? sdpMLineIndex) =>
    jsonEncode({
      'type': 'ice',
      'candidate': candidate,
      'sdpMid': sdpMid,
      'sdpMLineIndex': sdpMLineIndex,
    });

String encodeControl(String action, dynamic value) =>
    jsonEncode({'type': 'control', 'action': action, 'value': value});
