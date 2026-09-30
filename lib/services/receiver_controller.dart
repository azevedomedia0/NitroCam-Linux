import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:nitrocam_protocol/nitrocam_protocol.dart';
import 'package:window_manager/window_manager.dart';

import 'nitrocam_native.dart';
import 'signaling_server.dart';
import 'webrtc_answerer.dart';

enum AppConnectionState { disconnected, connecting, streaming }

class ReceiverController extends ChangeNotifier with WindowListener {
  final wifi = WifiSignalingServer();
  final rtc = WebRtcAnswerer();
  final audio = AudioReceiver();
  final previewKey = GlobalKey(debugLabel: 'preview');

  AppConnectionState connectionState = AppConnectionState.disconnected;
  String ipAddress = '127.0.0.1';
  String pairingCode = '···-···';
  bool hasV4l2 = false;
  int currentFps = 0;
  int _fpsCounter = 0;
  Timer? _fpsTimer;
  Timer? _sampleTimer;
  bool mirror = true;

  String get pairingUrl => buildPairingUrl(
        ip: ipAddress,
        port: kSignalingPort,
        pairCode: pairingCode.replaceAll(RegExp(r'\D'), '').padLeft(6, '0'),
      );

  Future<void> initialize() async {
    ipAddress = await getLocalIpAddress();
    pairingCode = generatePairCode(ipAddress);
    hasV4l2 = await NitrocamNative.isVirtualCameraAvailable();
    wifi.onMessage = _onSignal;
    wifi.onDisconnect = () {
      connectionState = AppConnectionState.disconnected;
      wifi.isSessionActive = false;
      _sampleTimer?.cancel();
      notifyListeners();
      windowManager.setTitle('NitroCam');
    };
    rtc.onIceCandidate = (c) {
      wifi.sendIce(c.candidate ?? '', c.sdpMid, c.sdpMLineIndex ?? 0);
    };
    rtc.onConnectionState = (s) {
      if (s == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        connectionState = AppConnectionState.streaming;
        wifi.isSessionActive = true;
        _startSampler();
        windowManager.setTitle('NitroCam — Live');
        notifyListeners();
      } else if (s ==
              webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          s ==
              webrtc
                  .RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          s == webrtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        connectionState = AppConnectionState.disconnected;
        wifi.isSessionActive = false;
        _sampleTimer?.cancel();
        windowManager.setTitle('NitroCam');
        notifyListeners();
      }
    };
    audio.onPcm = NitrocamNative.pushPcm;
    await wifi.start();
    await audio.start();
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentFps = _fpsCounter;
      _fpsCounter = 0;
      notifyListeners();
    });
    windowManager.addListener(this);
    notifyListeners();
  }

  void refreshPairingCode() {
    pairingCode = generatePairCode(ipAddress);
    notifyListeners();
  }

  Future<void> disconnect() async {
    _sampleTimer?.cancel();
    await rtc.cleanup();
    await wifi.rejectActiveConnection();
    connectionState = AppConnectionState.disconnected;
    wifi.isSessionActive = false;
    windowManager.setTitle('NitroCam');
    notifyListeners();
  }

  Future<void> _onSignal(SignalMessage msg) async {
    switch (msg) {
      case OfferMessage(:final sdp, :final pairCode):
        if (pairCode != null && pairCode.isNotEmpty) {
          final expected = pairingCode.replaceAll(RegExp(r'\D'), '');
          final got = pairCode.replaceAll(RegExp(r'\D'), '');
          final ok = got.length == 6 &&
              expected.length == 6 &&
              got.substring(3) == expected.substring(3);
          if (!ok) {
            await wifi.rejectActiveConnection();
            return;
          }
        }
        connectionState = AppConnectionState.connecting;
        notifyListeners();
        await rtc.createPeerConnection();
        try {
          final answer = await rtc.handleOffer(sdp);
          await wifi.sendAnswer(answer);
          await wifi.sendControl('mirror', mirror);
          await wifi.sendControl('host_ip', ipAddress);
        } catch (e) {
          stderr.writeln('offer failed: $e');
          connectionState = AppConnectionState.disconnected;
          notifyListeners();
        }
      case IceMessage(:final candidate, :final sdpMid, :final sdpMLineIndex):
        await rtc.addIceCandidate(
          candidate: candidate,
          sdpMLineIndex: sdpMLineIndex,
          sdpMid: sdpMid,
        );
      default:
        break;
    }
  }

  void _startSampler() {
    _sampleTimer?.cancel();
    _sampleTimer = Timer.periodic(const Duration(milliseconds: 33), (_) async {
      final boundary =
          previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      try {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (bytes == null) return;
        _fpsCounter++;
        final rgba = bytes.buffer.asUint8List();
        if (image.width == kOutputWidth && image.height == kOutputHeight) {
          final bgra = Uint8List(rgba.length);
          for (var i = 0; i < rgba.length; i += 4) {
            bgra[i] = rgba[i + 2];
            bgra[i + 1] = rgba[i + 1];
            bgra[i + 2] = rgba[i];
            bgra[i + 3] = rgba[i + 3];
          }
          await NitrocamNative.writeFrameBgra(bgra);
        }
        image.dispose();
      } catch (_) {}
    });
  }

  @override
  void onWindowClose() async {
    await disconnect();
    await wifi.stop();
    await audio.stop();
    await windowManager.destroy();
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    _sampleTimer?.cancel();
    wifi.stop();
    audio.stop();
    rtc.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }
}
