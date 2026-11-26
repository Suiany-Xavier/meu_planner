import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/main.dart';
import 'package:meu_planner/screens/add_task_dialog.dart';
import 'package:meu_planner/screens/tasks_screen.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';
import 'package:meu_planner/utils.dart';

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
  var account = 0;

  setUp(() {
    final email = 'regression${account++}@example.com';
    authService.register(email, 'senha-segura');
    authService.login(email, 'senha-segura');
    taskStore.useOwner(authService.currentEmail);
  });

  tearDown(() => authService.logout());

  testWidgets('calendário com tarefas cabe em tela estreita', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final day = DateTime.now();
    taskStore.add(day, 'Pendente');
    taskStore.add(day, 'Concluída');
    taskStore.toggle(day, taskStore.tasksOf(day).first.id);

    await tester.pumpWidget(
      MeuPlannerApp(authService: authService, taskStore: taskStore),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('trocar de mês seleciona uma data do mês exibido', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeuPlannerApp(authService: authService, taskStore: taskStore),
    );
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    final lastDay = DateTime(now.year, now.month + 2, 0).day;
    final expected = DateTime(
      nextMonth.year,
      nextMonth.month,
      now.day > lastDay ? lastDay : now.day,
    );

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-selected-day')));
    await tester.pumpAndSettle();

    expect(find.text('Dia ${formatDate(expected)}'), findsOneWidget);
  });

  testWidgets('Hoje volta ao mês atual e abre as tarefas de hoje', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeuPlannerApp(authService: authService, taskStore: taskStore),
    );
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();
    final today = DateTime.now();
    expect(find.text('Data selecionada: ${formatDate(today)}'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-selected-day')));
    await tester.pumpAndSettle();
    expect(find.text('Dia ${formatDate(today)}'), findsOneWidget);
  });

  testWidgets('escolhe mês e ano, valida ano e ajusta o dia selecionado', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeuPlannerApp(authService: authService, taskStore: taskStore),
    );
    // Seleciona o dia 31 de um mês que sempre tem 31 dias.
    await tester.tap(find.byTooltip('Escolher mês e ano'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.descendant(
        of: find.byType(Scrollable).last,
        matching: find.text('Janeiro'),
      ),
      -120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Janeiro').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2032');
    await tester.tap(find.text('Ir para o mês'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('31'));
    await tester.tap(find.text('31'));
    // Aguarda a distinção entre toque simples e toque duplo do calendário.
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byTooltip('Escolher mês e ano'));
    await tester.tap(find.byTooltip('Escolher mês e ano'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.text('Ir para o mês'));
    await tester.pumpAndSettle();
    expect(find.text('Digite um ano entre 1 e 9999.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), '2032');
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fevereiro').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir para o mês'));
    await tester.pumpAndSettle();
    expect(find.text('Fevereiro 2032'), findsOneWidget);
    expect(find.text('Data selecionada: 29/02/2032'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-selected-day')));
    await tester.pumpAndSettle();
    expect(find.text('Dia 29/02/2032'), findsOneWidget);
  });

  testWidgets('cancelar escolha de mês preserva a data selecionada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MeuPlannerApp(authService: authService, taskStore: taskStore),
    );
    final label = tester
        .widget<Text>(find.textContaining('Data selecionada:'))
        .data;
    await tester.tap(find.byTooltip('Escolher mês e ano'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '2040');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text(label!), findsOneWidget);
  });

  testWidgets('excluir por gesto e desfazer preserva as demais tarefas', (
    tester,
  ) async {
    final day = DateTime(2026, 11, 10);
    taskStore.add(day, 'Alfa');
    taskStore.add(day, 'Beta');
    await tester.pumpWidget(
      MaterialApp(
        home: TasksScreen(
          day: day,
          authService: authService,
          taskStore: taskStore,
        ),
      ),
    );

    await tester.drag(find.byType(Dismissible).first, const Offset(-1000, 0));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Alfa'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);

    await tester.tap(find.text('DESFAZER'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Alfa'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('formulário cabe em celular pequeno com teclado aberto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (_) => const AddTaskDialog(),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Nova atividade');
    await tester.ensureVisible(find.text('Adicionar'));
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.byType(AddTaskDialog), findsNothing);
  });
}
