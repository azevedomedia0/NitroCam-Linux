#!/usr/bin/env dart
import 'dart:io';
import 'package:image/image.dart';

void main() {
  final root = Directory.current.path;
  final icon = decodeImage(File('$root/assets/icon.png').readAsBytesSync())!;
  for (final size in [64, 128, 256, 512]) {
    final dir = Directory('$root/flathub/icons/hicolor/${size}x$size/apps')
      ..createSync(recursive: true);
    final resized = copyResize(icon, width: size, height: size);
    File('${dir.path}/com.azevedomedia.NitroCam.png')
        .writeAsBytesSync(encodePng(resized));
    stdout.writeln('icon ${size}x$size');
  }

  final shot = Image(width: 1920, height: 1080);
  fill(shot, color: ColorRgb8(14, 17, 22));
  for (var y = 0; y < 1080; y++) {
    final t = y / 1080;
    drawLine(
      shot,
      x1: 0,
      y1: y,
      x2: 1919,
      y2: y,
      color: ColorRgb8(
        (14 + 10 * t).round(),
        (17 + 12 * t).round(),
        (22 + 16 * t).round(),
      ),
    );
  }
  final logo = copyResize(icon, width: 220, height: 220);
  compositeImage(shot, logo, dstX: (1920 - 220) ~/ 2, dstY: 300);
  drawString(shot, 'NitroCam', font: arial48, x: 820, y: 560,
      color: ColorRgb8(242, 244, 247));
  drawString(
    shot,
    'Phone camera as a Linux virtual webcam',
    font: arial24,
    x: 680,
    y: 640,
    color: ColorRgb8(154, 163, 178),
  );
  final shots = Directory('$root/flathub/screenshots')..createSync(recursive: true);
  File('${shots.path}/overview.png').writeAsBytesSync(encodePng(shot));
  // Also copy for website publish path convenience
  File('${shots.path}/linux-overview.png').writeAsBytesSync(encodePng(shot));
  stdout.writeln('screenshot ok');
}
