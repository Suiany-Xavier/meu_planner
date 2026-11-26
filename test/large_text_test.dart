import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/main.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(800, 600)]) {
    testWidgets(
      'fontes a 200% permitem usar login, calendário e tarefas em $size',
      (tester) async {
        final auth = AuthService();
        final store = TaskStore();
        addTearDown(auth.dispose);
        addTearDown(store.dispose);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        auth.register('ana@example.com', '123456');
        await tester.pumpWidget(
          MeuPlannerApp(authService: auth, taskStore: store),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.byType(TextField).first);
        await tester.enterText(find.byType(TextField).first, 'ana@example.com');
        await tester.ensureVisible(find.byType(TextField).last);
        await tester.enterText(find.byType(TextField).last, '123456');
        await tester.ensureVisible(find.text('Entrar').last);
        await tester.tap(find.text('Entrar').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final now = DateTime.now();
        store.add(now, 'Tarefa com um título longo para conferir a leitura');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('open-selected-day')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.text('Tarefa com um título longo para conferir a leitura'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(
          find.text('Tarefa com um título longo para conferir a leitura'),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Adicionar tarefa'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.enterText(find.byType(TextField), 'Nova tarefa ampliada');
        await tester.ensureVisible(find.text('Adicionar'));
        await tester.tap(find.text('Adicionar'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        expect(
          store.tasksOf(now).map((task) => task.title),
          contains('Nova tarefa ampliada'),
        );
      },
    );
  }
}
