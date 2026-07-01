import 'package:flutter_test/flutter_test.dart';
import 'package:rugby_jam_mobile/app/rugby_jam_app.dart';

void main() {
  testWidgets('shows RugbyJam home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RugbyJamApp());

    expect(find.text('RugbyJam'), findsWidgets);
    expect(find.text('Le rugby, partout, facilement'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('navigates to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RugbyJamApp());

    await tester.tap(find.text('Se connecter').first);
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
  });
}
