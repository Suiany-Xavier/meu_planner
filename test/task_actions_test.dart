import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/screens/tasks_screen.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';

void main() {
  late AuthService authService;
  late TaskStore taskStore;
  setUp(() {
    authService = AuthService();
    taskStore = TaskStore();
  });
  tearDown(() {
    authService.dispose();
    taskStore.dispose();
  });
  final day = DateTime(2026, 11, 10);
  var owner = 0;

  setUp(() => taskStore.useOwner('actions${owner++}@example.com'));
  tearDown(() => taskStore.useOwner(null));

  Future<void> openTasks(WidgetTester tester) async {
    taskStore.add(day, 'Minha tarefa');
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: TasksScreen(
          day: day,
          authService: authService,
          taskStore: taskStore,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> action(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip('Opções da tarefa: Minha tarefa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('editar valida título vazio e salva a tarefa concluída', (
    tester,
  ) async {
    await openTasks(tester);
    final task = taskStore.tasksOf(day).single;
    taskStore.toggle(day, task.id);
    await tester.pumpAndSettle();
    await action(tester, 'Editar tarefa');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Minha tarefa',
    );
    await tester.enterText(find.byType(TextField), '  ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Escreva o nome da tarefa primeiro 😉'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' Tarefa editada ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Tarefa editada'), findsOneWidget);
    expect(taskStore.tasksOf(day).single.id, task.id);
    expect(taskStore.tasksOf(day).single.done, isTrue);
  });

  testWidgets('transferir muda a data e permite abrir o destino', (
    tester,
  ) async {
    await openTasks(tester);
    final task = taskStore.tasksOf(day).single;
    taskStore.toggle(day, task.id);
    await tester.pumpAndSettle();
    await action(tester, 'Transferir para outra data');
    await tester.tap(find.text('11').last);
    await tester.tap(find.text('Transferir'));
    await tester.pumpAndSettle();
    final target = DateTime(2026, 11, 11);
    expect(taskStore.tasksOf(day), isEmpty);
    expect(taskStore.tasksOf(target).single.id, task.id);
    expect(taskStore.tasksOf(target).single.done, isTrue);
    expect(find.text('Tarefa transferida para 11/11/2026.'), findsOneWidget);
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();
    expect(find.text('Dia 11/11/2026'), findsOneWidget);
    expect(find.text('Minha tarefa'), findsOneWidget);
  });

  testWidgets('cancelar edição ou transferência não altera a tarefa', (
    tester,
  ) async {
    await openTasks(tester);
    await action(tester, 'Editar tarefa');
    await tester.enterText(find.byType(TextField), 'Não salvar');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(taskStore.tasksOf(day).single.title, 'Minha tarefa');
    await action(tester, 'Transferir para outra data');
    await tester.tap(find.text('11').last);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(taskStore.tasksOf(day).single.title, 'Minha tarefa');
    expect(taskStore.tasksOf(DateTime(2026, 11, 11)), isEmpty);
  });

  testWidgets('excluir pelo menu continua permitindo desfazer', (tester) async {
    await openTasks(tester);
    await action(tester, 'Excluir tarefa');
    expect(taskStore.tasksOf(day), isEmpty);
    await tester.tap(find.text('DESFAZER'));
    await tester.pumpAndSettle();
    expect(find.text('Minha tarefa'), findsOneWidget);
  });
}
