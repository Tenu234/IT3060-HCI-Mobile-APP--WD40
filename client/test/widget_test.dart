import 'package:client/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts on the login screen when not logged in', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OpdApp());
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
