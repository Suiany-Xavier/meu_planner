import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/main.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';
import 'package:meu_planner/utils.dart';

void main() {
  late AuthService auth;
  late TaskStore store;

  setUp(() {
    auth = AuthService();
    store = TaskStore();
    auth.register('datas@example.com', '123456');
    auth.login('datas@example.com', '123456');
  });
  tearDown(() {
    auth.dispose();
    store.dispose();
  });

  Future<void> chooseMonth(WidgetTester tester, String month, int year) async {
    await tester.ensureVisible(find.byTooltip('Escolher mês e ano'));
    await tester.tap(find.byTooltip('Escolher mês e ano'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    // Começa pelo início para não depender do mês em que o teste é executado.
    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.descendant(of: scrollable, matching: find.text('Janeiro')),
      -160,
      scrollable: scrollable,
    );
    await tester.scrollUntilVisible(
      find.descendant(of: scrollable, matching: find.text(month)),
      160,
      scrollable: scrollable,
    );
    await tester.tap(
      find.descendant(of: scrollable, matching: find.text(month)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '$year');
    await tester.tap(find.text('Ir para o mês'));
    await tester.pumpAndSettle();
  }

  // Inclui as exceções de século: 1900 não é bissexto, mas 2000 é.
  for (final scenario in [(2027, 28), (2028, 29), (1900, 28), (2000, 29)]) {
    final (year, lastDay) = scenario;
    testWidgets('janeiro para fevereiro de $year seleciona dia $lastDay', (
      tester,
    ) async {
      await tester.pumpWidget(
        MeuPlannerApp(authService: auth, taskStore: store),
      );
      await chooseMonth(tester, 'Janeiro', year);
      await tester.ensureVisible(find.text('31'));
      await tester.tap(find.text('31'));
      // Aguarda a distinção entre toque simples e toque duplo do calendário.
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Próximo mês'));
      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
      expect(find.text('Fevereiro $year'), findsOneWidget);
      expect(
        find.text(
          'Data selecionada: ${formatDate(DateTime(year, 2, lastDay))}',
        ),
        findsOneWidget,
      );
      expect(find.text('$lastDay'), findsOneWidget);
      expect(find.text('${lastDay + 1}'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('open-selected-day')));
      await tester.pumpAndSettle();
      expect(
        find.text('Dia ${formatDate(DateTime(year, 2, lastDay))}'),
        findsOneWidget,
      );
    });
  }

  testWidgets(
    'dezembro e janeiro navegam nos dois sentidos sem perder tarefas',
    (tester) async {
      await tester.pumpWidget(
        MeuPlannerApp(authService: auth, taskStore: store),
      );
      final december = DateTime(2026, 12, 31);
      final january = DateTime(2027, 1, 31);
      store.add(december, 'Fechar o ano');
      store.add(january, 'Planejar o ano');
      await chooseMonth(tester, 'Dezembro', 2026);
      await tester.ensureVisible(find.text('31'));
      await tester.tap(find.text('31'));
      // Aguarda a distinção entre toque simples e toque duplo do calendário.
      await tester.pump(kDoubleTapTimeout);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Próximo mês'));
      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
      expect(find.text('Janeiro 2027'), findsOneWidget);
      expect(find.text('Data selecionada: 31/01/2027'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-selected-day')));
      await tester.pumpAndSettle();
      expect(find.text('Planejar o ano'), findsOneWidget);
      expect(find.text('Fechar o ano'), findsNothing);
      await tester.tap(find.byTooltip('Voltar ao calendário'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byTooltip('Mês anterior'));
      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Data selecionada: 31/12/2026'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-selected-day')));
      await tester.pumpAndSettle();
      expect(find.text('Fechar o ano'), findsOneWidget);
      expect(find.text('Planejar o ano'), findsNothing);
    },
  );
}
