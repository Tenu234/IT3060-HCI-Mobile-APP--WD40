import 'package:client/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts on the admin sign-in screen when not logged in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OpdApp());
    await tester.pumpAndSettle();
    expect(find.text('Admin sign in'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
