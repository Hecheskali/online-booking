import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:online_booking/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('login page renders auth actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
