import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/main.dart';
import 'package:meu_planner/screens/tasks_screen.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';
import 'package:meu_planner/utils.dart';
import 'package:meu_planner/widgets.dart';

void main() {
  late AuthService auth;
  late TaskStore store;

  setUp(() {
    auth = AuthService();
    store = TaskStore();
    auth.register('ana@example.com', '123456');
  });
  tearDown(() {
    auth.dispose();
    store.dispose();
  });

  void resize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }

  Future<void> openDesktop(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
  }) async {
    resize(tester, size);
    addTearDown(tester.view.reset);
    auth.login('ana@example.com', '123456');
    await tester.pumpWidget(MeuPlannerApp(authService: auth, taskStore: store));
    await tester.pumpAndSettle();
  }

  Future<void> selectDay(WidgetTester tester, DateTime day) async {
    final cell = find.byKey(ValueKey(day));
    // A mesma chave identifica o painel e a célula; seleciona a célula do calendário.
    final calendarCell = find.byWidgetPredicate(
      (widget) => widget.key == ValueKey(day) && widget is! TasksScreen,
    );
    expect(cell, findsWidgets);
    await tester.ensureVisible(calendarCell);
    await tester.tap(calendarCell);
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'login tem largura limitada e fica centralizado em monitor grande',
    (tester) async {
      resize(tester, const Size(1920, 1080));
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MeuPlannerApp(authService: auth, taskStore: store),
      );
      await tester.pumpAndSettle();
      final email = tester.getRect(find.byType(TextField).first);
      expect(email.width, lessThan(480));
      expect(email.center.dx, closeTo(960, 12));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selecionar data atualiza tarefas ao lado sem abrir outra rota', (
    tester,
  ) async {
    await openDesktop(tester);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final otherDay = DateTime(now.year, now.month, now.day == 1 ? 2 : 1);
    store.add(today, 'Atividade de hoje');
    store.add(otherDay, 'Atividade de outro dia');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-planner')), findsOneWidget);
    expect(find.byKey(const ValueKey('open-selected-day')), findsNothing);
    expect(find.text('Atividade de hoje'), findsOneWidget);
    final pane = tester.widget<TasksScreen>(find.byType(TasksScreen));
    expect(pane.embedded, isTrue);
    await selectDay(tester, otherDay);
    expect(find.text('Dia ${formatDate(otherDay)}'), findsOneWidget);
    expect(find.text('Atividade de outro dia'), findsOneWidget);
    expect(find.text('Atividade de hoje'), findsNothing);
    expect(
      Navigator.of(tester.element(find.byType(TasksScreen))).canPop(),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'criação, edição e transferência funcionam no painel do computador',
    (tester) async {
      await openDesktop(tester);
      final now = DateTime.now();
      final source = DateTime(now.year, now.month, now.day);
      final target = DateTime(now.year, now.month, now.day == 1 ? 2 : 1);
      await tester.tap(find.byTooltip('Adicionar tarefa'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(Dialog),
                matching: find.byType(NeoBox),
              ),
            )
            .width,
        lessThanOrEqualTo(480),
      );
      await tester.enterText(find.byType(TextField), 'Planejar');
      await tester.tap(find.text('Adicionar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opções da tarefa: Planejar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar tarefa'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Planejar a semana');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Planejar a semana'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Opções da tarefa: Planejar a semana'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transferir para outra data'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('${target.day}').last);
      await tester.tap(find.text('Transferir'));
      await tester.pumpAndSettle();
      expect(store.tasksOf(source), isEmpty);
      expect(store.tasksOf(target).single.done, isTrue);
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('desktop-planner')), findsOneWidget);
      expect(find.text('Dia ${formatDate(target)}'), findsOneWidget);
      expect(
        find.text('Data selecionada: ${formatDate(target)}'),
        findsOneWidget,
      );
      expect(find.text('Planejar a semana'), findsOneWidget);
      expect(
        Navigator.of(tester.element(find.byType(TasksScreen))).canPop(),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('redimensionar preserva data e tarefas entre os layouts', (
    tester,
  ) async {
    await openDesktop(tester);
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, 1);
    await selectDay(tester, day);
    store.add(day, 'Preservar ao redimensionar');
    await tester.pumpAndSettle();
    resize(tester, const Size(390, 844));
    await tester.pumpAndSettle();
    expect(find.byType(TasksScreen), findsNothing);
    expect(find.text('Data selecionada: ${formatDate(day)}'), findsOneWidget);
    expect(find.byKey(const ValueKey('open-selected-day')), findsOneWidget);
    expect(tester.takeException(), isNull);
    resize(tester, const Size(1440, 900));
    await tester.pumpAndSettle();
    expect(find.text('Preservar ao redimensionar'), findsOneWidget);
    expect(find.text('Dia ${formatDate(day)}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('janela larga e baixa mantém calendário e tarefas roláveis', (
    tester,
  ) async {
    await openDesktop(tester, size: const Size(1280, 480));
    store.add(DateTime.now(), 'Tarefa em janela baixa');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-planner')), findsOneWidget);
    expect(find.byTooltip('Adicionar tarefa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('desktop-planner')), findsNothing);
    expect(find.byKey(const ValueKey('open-selected-day')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
