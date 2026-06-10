import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MusicApp());
    expect(find.text('Music Library'), findsOneWidget);
  });
}
