String generatePairCode(String ip) {
  final parts = ip.split('.');
  var last = 0;
  if (parts.length == 4) last = int.tryParse(parts[3]) ?? 0;
  final rand = DateTime.now().millisecondsSinceEpoch % 1000;
  return '${rand.toString().padLeft(3, '0')}-${last.toString().padLeft(3, '0')}';
}

String buildPairingUrl({
  required String ip,
  required int port,
  required String pairCode,
}) {
  final digits = pairCode.replaceAll(RegExp(r'\D'), '');
  return 'nitrocam://$ip:$port?pair=$digits';
}

String? decodePairCode(String code, String subnet) {
  final digits = code.replaceAll(RegExp(r'\D'), '');
  if (digits.length != 6 || subnet.isEmpty) return null;
  final last = int.tryParse(digits.substring(3));
  if (last == null || last < 1 || last > 254) return null;
  return '$subnet.$last';
}
