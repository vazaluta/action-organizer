import 'package:flutter_test/flutter_test.dart';
import 'package:action_organizer_app/main.dart';

void main() {
  testWidgets('週報フォームが表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const WeeklyReportApp());
    expect(find.text('週報'), findsOneWidget);
    expect(find.text('1. 今週の振り返り'), findsOneWidget);
  });
}
