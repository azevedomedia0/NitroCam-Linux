import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nitrocam_protocol/nitrocam_protocol.dart';

typedef MsgHandler = void Function(SignalMessage message);

class WifiSignalingServer {
  HttpServer? _server;
  WebSocket? _socket;
  bool isSessionActive = false;
  MsgHandler? onMessage;
  void Function()? onDisconnect;

  Future<void> start({int port = kSignalingPort}) async {
    await stop();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_onHttp);
  }

  Future<void> stop() async {
    await rejectActiveConnection();
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> rejectActiveConnection() async {
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
  }

  Future<void> sendRaw(String json) async => _socket?.add(json);
  Future<void> sendAnswer(String sdp) => sendRaw(encodeAnswer(sdp));
  Future<void> sendIce(String c, String? mid, int idx) =>
      sendRaw(encodeIce(c, mid, idx));
  Future<void> sendControl(String action, dynamic value) =>
      sendRaw(encodeControl(action, value));

  Future<void> _onHttp(HttpRequest req) async {
    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      req.response.statusCode = HttpStatus.badRequest;
      await req.response.close();
      return;
    }
    if (isSessionActive && _socket != null) {
      req.response.statusCode = HttpStatus.serviceUnavailable;
      await req.response.close();
      return;
    }
    final ws = await WebSocketTransformer.upgrade(req);
    await rejectActiveConnection();
    _socket = ws;
    ws.listen(
      (e) {
        final raw = e is String ? e : utf8.decode(e as List<int>);
        final msg = decodeSignal(raw);
        if (msg != null) onMessage?.call(msg);
      },
      onDone: () {
        _socket = null;
        onDisconnect?.call();
      },
      onError: (_) {
        _socket = null;
        onDisconnect?.call();
      },
      cancelOnError: true,
    );
  }
}
