import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/main.dart';
import 'package:legalguide_app/services/connectivity_status_service.dart';

void main() {
  tearDown(() {
    ConnectivityStatusService.stop();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LegalGuideApp());
    expect(find.byType(LegalGuideApp), findsOneWidget);
    ConnectivityStatusService.stop();
  });
}
