import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:nitrocam_protocol/nitrocam_protocol.dart';

class WebRtcAnswerer {
  webrtc.RTCPeerConnection? _pc;
  webrtc.MediaStream? _remote;
  webrtc.RTCVideoRenderer? previewRenderer;

  void Function(webrtc.RTCIceCandidate)? onIceCandidate;
  void Function(webrtc.RTCPeerConnectionState)? onConnectionState;

  Future<webrtc.RTCVideoRenderer> ensurePreview() async {
    if (previewRenderer != null) return previewRenderer!;
    final r = webrtc.RTCVideoRenderer();
    await r.initialize();
    previewRenderer = r;
    return r;
  }

  Future<bool> createPeerConnection() async {
    await cleanup();
    final pc = await webrtc.createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });
    pc.onIceCandidate = (c) {
      if (c.candidate != null) onIceCandidate?.call(c);
    };
    pc.onConnectionState = (s) => onConnectionState?.call(s);
    pc.onTrack = (e) async {
      if (e.track.kind == 'video') {
        _remote ??= await webrtc.createLocalMediaStream('remote');
        await _remote!.addTrack(e.track);
        (await ensurePreview()).srcObject = _remote;
      }
    };
    _pc = pc;
    return true;
  }

  Future<String> handleOffer(String sdp) async {
    final pc = _pc;
    if (pc == null) throw StateError('No peer connection');
    await pc.setRemoteDescription(webrtc.RTCSessionDescription(sdp, 'offer'));
    final answer = await pc.createAnswer({
      'offerToReceiveVideo': 1,
      'offerToReceiveAudio': 1,
    });
    final munged = (answer.sdp ?? '').replaceAllMapped(
      RegExp(r'profile-level-id=([0-9a-fA-F]{4})([0-9a-fA-F]{2})'),
      (m) => 'profile-level-id=${m.group(1)}34',
    );
    final local = webrtc.RTCSessionDescription(munged, 'answer');
    await pc.setLocalDescription(local);
    return local.sdp ?? munged;
  }

  Future<void> addIceCandidate({
    required String candidate,
    required int sdpMLineIndex,
    String? sdpMid,
  }) async {
    await _pc?.addCandidate(
      webrtc.RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
    );
  }

  Future<void> cleanup() async {
    await _remote?.dispose();
    _remote = null;
    await _pc?.close();
    _pc = null;
  }

  Future<void> dispose() async {
    await cleanup();
    await previewRenderer?.dispose();
    previewRenderer = null;
  }
}

class AudioReceiver {
  ServerSocket? _server;
  void Function(Uint8List pcm)? onPcm;

  Future<void> start({int port = kAudioPort}) async {
    await stop();
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _server!.listen((sock) {
      sock.listen((data) => onPcm?.call(Uint8List.fromList(data)));
    });
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}

Future<String> getLocalIpAddress() async {
  try {
    final ifaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    String? fallback;
    for (final i in ifaces) {
      for (final a in i.addresses) {
        final ip = a.address;
        if (ip.startsWith('127.')) continue;
        if (ip.startsWith('192.168.') ||
            ip.startsWith('10.') ||
            ip.startsWith('172.')) {
          return ip;
        }
        fallback ??= ip;
      }
    }
    return fallback ?? '127.0.0.1';
  } catch (_) {
    return '127.0.0.1';
  }
}
