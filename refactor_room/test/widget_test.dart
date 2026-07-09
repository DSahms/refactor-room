import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refactor_room/app.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    dotenv.testLoad(fileInput: 'LLM_BACKEND=venice\nVENICE_API_KEY=test\n');
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: RefactorRoomApp(),
      ),
    );
    expect(find.text('The Refactor '), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
  });
}
