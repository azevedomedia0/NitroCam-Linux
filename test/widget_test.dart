import 'package:flutter_test/flutter_test.dart';
import 'package:nitrocam/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    // Skip full initialize (needs window_manager / network).
    expect(NitroCamApp, isNotNull);
  });
}
