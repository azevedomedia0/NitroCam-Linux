import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:nitrocam_protocol/nitrocam_protocol.dart';

class NitrocamNative {
  static const _ch = MethodChannel('com.azevedomedia.NitroCam/native');

  static Future<bool> writeFrameBgra(Uint8List bgra) async {
    try {
      return await _ch.invokeMethod<bool>('writeFrame', {
            'width': kOutputWidth,
            'height': kOutputHeight,
            'bgra': bgra,
          }) ??
          false;
    } on MissingPluginException {
      return _writeDev(bgra);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pushPcm(Uint8List pcm) async {
    try {
      return await _ch.invokeMethod<bool>('pushPcm', {'pcm': pcm}) ?? false;
    } on MissingPluginException {
      try {
        await File('/tmp/nitrocam_mic.pcm')
            .writeAsBytes(pcm, mode: FileMode.append, flush: false);
        return true;
      } catch (_) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isVirtualCameraAvailable() async {
    try {
      return await _ch.invokeMethod<bool>('hasV4l2') ?? _findLoopback() != null;
    } on MissingPluginException {
      return _findLoopback() != null;
    } catch (_) {
      return _findLoopback() != null;
    }
  }

  static String? _findLoopback() {
    for (var i = 10; i <= 20; i++) {
      final p = '/dev/video$i';
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  static Future<bool> _writeDev(Uint8List bgra) async {
    final path = _findLoopback();
    if (path == null) return false;
    try {
      final f = await File(path).open(mode: FileMode.write);
      await f.writeFrom(bgra);
      await f.close();
      return true;
    } catch (_) {
      return false;
    }
  }
}
