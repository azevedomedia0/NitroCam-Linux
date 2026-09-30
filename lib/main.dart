import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'services/receiver_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    size: Size(960, 640),
    minimumSize: Size(720, 480),
    center: true,
    title: 'NitroCam',
  );
  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  final c = ReceiverController();
  await c.initialize();
  runApp(ChangeNotifierProvider.value(value: c, child: const NitroCamApp()));
}

class NitroCamApp extends StatelessWidget {
  const NitroCamApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NitroCam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8A23A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ReceiverController>(
      builder: (context, vm, _) {
        final live = vm.connectionState == AppConnectionState.streaming;
        return Scaffold(
          backgroundColor: const Color(0xFF0E1116),
          body: SafeArea(
            child: live ? _Live(vm: vm) : _Pair(vm: vm),
          ),
        );
      },
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.vm});
  final ReceiverController vm;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NitroCam',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Use your phone as a virtual camera on Linux.',
                    style: TextStyle(color: Color(0xFF9AA3B2))),
                const Spacer(),
                Text('LAN IP  ${vm.ipAddress}',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                Text('Pair    ${vm.pairingCode}',
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 12),
                OutlinedButton(
                    onPressed: vm.refreshPairingCode,
                    child: const Text('Refresh code')),
                if (!vm.hasV4l2) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Install host v4l2loopback for virtual camera:\n'
                    '  sudo modprobe v4l2loopback devices=1 video_nr=10 card_label=NitroCam',
                    style: TextStyle(color: Color(0xFFE8A23A), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF171B22),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(data: vm.pairingUrl, size: 220, backgroundColor: Colors.white),
                const SizedBox(height: 12),
                SelectableText(vm.pairingUrl,
                    style: const TextStyle(color: Color(0xFF9AA3B2), fontSize: 11),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Live extends StatelessWidget {
  const _Live({required this.vm});
  final ReceiverController vm;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: vm.rtc.previewRenderer == null
                  ? const Center(child: Text('No preview'))
                  : RepaintBoundary(
                      key: vm.previewKey,
                      child: webrtc.RTCVideoView(
                        vm.rtc.previewRenderer!,
                        objectFit: webrtc
                            .RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${vm.currentFps} fps',
                  style: const TextStyle(color: Color(0xFF9AA3B2))),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: vm.disconnect,
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
