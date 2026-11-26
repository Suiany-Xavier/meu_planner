import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/main.dart';
import 'package:meu_planner/screens/tasks_screen.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';
import 'package:meu_planner/utils.dart';
import 'package:meu_planner/widgets.dart';

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
  testWidgets(
    'botões aceitam Tab, Shift+Tab, Enter e Espaço com foco visível',
    (tester) async {
      var first = 0;
      var second = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                NeoButton(
                  onPressed: () => first++,
                  child: const Text('Primeiro'),
                ),
                NeoButton(
                  onPressed: () => second++,
                  semanticLabel: 'Segundo',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Primeiro')),
        isSemantics(
          isButton: true,
          isFocusable: true,
          isFocused: true,
          hasTapAction: true,
        ),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(
        (container.decoration! as BoxDecoration).boxShadow,
        containsAll(focusRing),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(first, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(second, 1);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('Primeiro')),
        isSemantics(isFocused: true),
      );
    },
  );

  testWidgets('campos têm rótulos, avançam para senha e anunciam erros', (
    tester,
  ) async {
    authService.logout();
    await tester.pumpWidget(
      MeuPlannerApp(authService: authService, taskStore: taskStore),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Email')),
      isSemantics(isTextField: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Senha')),
      isSemantics(isTextField: true, isObscured: true),
    );
    await tester.tap(find.byType(TextField).first);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    final password = tester.widget<EditableText>(
      find.byType(EditableText).last,
    );
    expect(password.focusNode.hasFocus, isTrue);
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Preencha e-mail e senha.')),
      isSemantics(isLiveRegion: true),
    );
  });

  testWidgets(
    'calendário permite selecionar por teclado e anuncia estado e contagem',
    (tester) async {
      authService.register('acessibilidade@example.com', '123456');
      authService.login('acessibilidade@example.com', '123456');
      taskStore.useOwner(authService.currentEmail);
      addTearDown(authService.logout);
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, 1);
      taskStore.add(day, 'Pendente');
      taskStore.add(day, 'Concluída');
      taskStore.toggle(day, taskStore.tasksOf(day).first.id);
      await tester.pumpWidget(
        MeuPlannerApp(authService: authService, taskStore: taskStore),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Sair'), findsOneWidget);
      expect(find.bySemanticsLabel('Mês anterior'), findsOneWidget);
      expect(find.bySemanticsLabel('Próximo mês'), findsOneWidget);
      final firstDay = find.bySemanticsLabel(
        RegExp(r'^1 de .*1 tarefa pendente, 1 tarefa concluída\.'),
      );
      expect(firstDay, findsOneWidget);
      for (var i = 0; i < 40; i++) {
        if (isSemantics(isFocused: true)
            .matches(tester.getSemantics(firstDay), {})) {
          break;
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(tester.getSemantics(firstDay), isSemantics(isFocused: true));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(firstDay), isSemantics(isSelected: true));
      expect(find.text('Data selecionada: ${formatDate(day)}'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Data selecionada: ${formatDate(DateTime(now.year, now.month, 2))}',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'conclusão funciona pelo teclado e expõe estado de caixa marcada',
    (tester) async {
      taskStore.useOwner('checkbox@example.com');
      addTearDown(() => taskStore.useOwner(null));
      final day = DateTime(2026, 11, 10);
      taskStore.add(day, 'Ler um livro');
      taskStore.add(day, 'Outra tarefa');
      await tester.pumpWidget(
        MaterialApp(
          home: TasksScreen(
            day: day,
            authService: authService,
            taskStore: taskStore,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Adicionar tarefa'), findsOneWidget);
      expect(find.bySemanticsLabel('Voltar ao calendário'), findsOneWidget);
      final checkbox = find.bySemanticsLabel('Ler um livro');
      expect(
        tester.getSemantics(checkbox),
        isSemantics(
          hasCheckedState: true,
          isChecked: false,
          hint: 'Marcar como concluída',
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(tester.getSemantics(checkbox), isSemantics(isFocused: true));
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(
        taskStore
            .tasksOf(day)
            .firstWhere((task) => task.title == 'Ler um livro')
            .done,
        isTrue,
      );
      expect(
        tester.getSemantics(checkbox),
        isSemantics(
          isChecked: true,
          isFocused: true,
          hint: 'Marcar como pendente',
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        taskStore
            .tasksOf(day)
            .firstWhere((task) => task.title == 'Ler um livro')
            .done,
        isFalse,
      );
    },
  );
}
