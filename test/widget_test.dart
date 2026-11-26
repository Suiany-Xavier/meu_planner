// Este é um teste básico de widget do Flutter.
//
// Para interagir com um widget no teste, use a ferramenta WidgetTester
// do pacote flutter_test. Por exemplo, você pode simular toques e gestos
// de rolagem. Também é possível usar WidgetTester para encontrar widgets filhos na
// árvore de widgets, ler textos e verificar os valores de suas propriedades.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meu_planner/main.dart';
import 'package:meu_planner/widgets.dart';

void main() {
  testWidgets('cadastra, entra e abre o calendário', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MeuPlannerApp());
    await tester.pumpAndSettle();

    expect(find.text('Meu Planner'), findsOneWidget);

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'senha-segura');
    await tester.tap(find.text('Cadastrar').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'senha-segura');
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo,'), findsOneWidget);
    expect(find.text('Test!'), findsOneWidget);
    expect(find.byType(NeoButton), findsWidgets);
  });
}
