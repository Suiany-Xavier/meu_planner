import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/main.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';

void main() {
  late AuthService auth;
  late TaskStore store;

  setUp(() {
    auth = AuthService();
    store = TaskStore();
    auth.register('ana@example.com', '123456');
    auth.register('bia@example.com', '123456');
  });
  tearDown(() {
    auth.dispose();
    store.dispose();
  });

  Future<void> login(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextField).first, email);
    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.text('Entrar').last);
    await tester.pumpAndSettle();
  }

  Future<void> openDay(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('open-selected-day')));
    await tester.pumpAndSettle();
  }

  Future<void> addTask(WidgetTester tester, String title) async {
    await tester.tap(find.byTooltip('Adicionar tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), title);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('sair e entrar com outra conta mantém as tarefas separadas', (
    tester,
  ) async {
    await tester.pumpWidget(MeuPlannerApp(authService: auth, taskStore: store));
    await login(tester, 'ana@example.com');
    await openDay(tester);
    await addTask(tester, 'Tarefa da Ana');
    expect(find.text('Tarefa da Ana'), findsOneWidget);
    await tester.tap(find.byTooltip('Voltar ao calendário'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await login(tester, 'bia@example.com');
    await openDay(tester);
    expect(find.text('Tarefa da Ana'), findsNothing);
    await addTask(tester, 'Tarefa da Bia');
    await tester.tap(find.byTooltip('Voltar ao calendário'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    await login(tester, 'ana@example.com');
    await openDay(tester);
    expect(find.text('Tarefa da Ana'), findsOneWidget);
    expect(find.text('Tarefa da Bia'), findsNothing);
  });

  testWidgets(
    'senha incorreta mantém o login fechado e permite tentar novamente',
    (tester) async {
      await tester.pumpWidget(
        MeuPlannerApp(authService: auth, taskStore: store),
      );
      await tester.enterText(find.byType(TextField).first, 'ana@example.com');
      await tester.enterText(find.byType(TextField).last, 'errada');
      await tester.tap(find.text('Entrar').last);
      await tester.pumpAndSettle();
      expect(auth.isLoggedIn, isFalse);
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      expect(find.byKey(const ValueKey('open-selected-day')), findsNothing);
      await login(tester, 'ana@example.com');
      expect(find.text('Ana!'), findsOneWidget);
    },
  );

  testWidgets(
    'criar, concluir, excluir e desfazer atualiza lista e calendário',
    (tester) async {
      await tester.pumpWidget(
        MeuPlannerApp(authService: auth, taskStore: store),
      );
      await login(tester, 'ana@example.com');
      await openDay(tester);
      await addTask(tester, 'Ler');
      await tester.tap(find.bySemanticsLabel('Ler'));
      await tester.pumpAndSettle();
      expect(find.text('0 pendentes  •  1 concluída'), findsOneWidget);
      await tester.tap(find.byTooltip('Opções da tarefa: Ler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir tarefa'));
      await tester.pumpAndSettle();
      expect(find.text('Dia livre por enquanto'), findsOneWidget);
      await tester.tap(find.text('DESFAZER'));
      await tester.pumpAndSettle();
      expect(find.text('Ler'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Ler')),
        isSemantics(isChecked: true),
      );
      await tester.tap(find.byTooltip('Voltar ao calendário'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(r'hoje\. 0 tarefas pendentes, 1 tarefa concluída\.'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Esc cancela a criação sem adicionar tarefas', (tester) async {
    await tester.pumpWidget(MeuPlannerApp(authService: auth, taskStore: store));
    await login(tester, 'ana@example.com');
    await openDay(tester);
    await tester.tap(find.byTooltip('Adicionar tarefa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Não salvar');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Nova tarefa'), findsNothing);
    expect(find.text('Não salvar'), findsNothing);
    expect(find.text('Dia livre por enquanto'), findsOneWidget);
  });
}
