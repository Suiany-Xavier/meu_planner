import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/main.dart';
import 'package:meu_planner/screens/auth_screen.dart';
import 'package:meu_planner/screens/calendar_screen.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';

void main() {
  test(
    'autenticações e armazenamentos independentes não compartilham estado',
    () {
      final firstAuth = AuthService();
      final secondAuth = AuthService();
      final firstStore = TaskStore();
      final secondStore = TaskStore();
      addTearDown(firstAuth.dispose);
      addTearDown(secondAuth.dispose);
      addTearDown(firstStore.dispose);
      addTearDown(secondStore.dispose);
      final day = DateTime(2026, 11, 10);
      firstStore.useOwner('ana@example.com');
      firstStore.add(day, 'Somente no primeiro');
      secondStore.useOwner('ana@example.com');
      firstAuth.register('ana@example.com', 'primeira');
      secondAuth.register('ana@example.com', 'segunda');
      expect(firstAuth.login('ana@example.com', 'primeira'), isNull);
      expect(secondAuth.isLoggedIn, isFalse);
      expect(secondAuth.login('ana@example.com', 'segunda'), isNull);
      secondAuth.logout();
      expect(firstAuth.isLoggedIn, isTrue);
      // Login e logout não modificam o dono nem as tarefas de um armazenamento.
      expect(firstStore.tasksOf(day).single.title, 'Somente no primeiro');
      expect(secondStore.tasksOf(day), isEmpty);
    },
  );

  test(
    'consultas são snapshots imutáveis e alterações passam pelo armazenamento',
    () {
      final store = TaskStore();
      addTearDown(store.dispose);
      final day = DateTime(2026, 11, 10);
      store.add(day, 'Título original');
      final snapshot = store.tasksOf(day);
      final task = snapshot.single;
      expect(() => snapshot.clear(), throwsUnsupportedError);
      var notifications = 0;
      store.addListener(() => notifications++);
      store.toggle(day, task.id);
      store.update(day, task.id, title: 'Novo título');
      expect(notifications, 2);
      expect(task.done, isFalse);
      expect(task.title, 'Título original');
      expect(store.tasksOf(day).single.done, isTrue);
      expect(store.tasksOf(day).single.title, 'Novo título');
      expect(store.tasksOf(day).single.id, task.id);
    },
  );

  testWidgets(
    'app coordena tarefas por usuário e preserva serviços injetados',
    (tester) async {
      final auth = AuthService();
      final store = TaskStore();
      addTearDown(auth.dispose);
      addTearDown(store.dispose);
      auth.register('ana@example.com', '123456');
      auth.register('bia@example.com', '123456');
      final day = DateTime(2026, 11, 10);
      await tester.pumpWidget(
        MeuPlannerApp(authService: auth, taskStore: store),
      );
      expect(find.byType(AuthScreen), findsOneWidget);
      auth.login('ana@example.com', '123456');
      await tester.pumpAndSettle();
      expect(find.byType(CalendarScreen), findsOneWidget);
      expect(
        tester.widget<CalendarScreen>(find.byType(CalendarScreen)).taskStore,
        same(store),
      );
      store.add(day, 'Da Ana');
      auth.logout();
      await tester.pumpAndSettle();
      expect(store.tasksOf(day), isEmpty);
      expect(find.byType(AuthScreen), findsOneWidget);
      auth.login('bia@example.com', '123456');
      await tester.pumpAndSettle();
      expect(store.tasksOf(day), isEmpty);
      store.add(day, 'Da Bia');
      auth.login('ana@example.com', '123456');
      await tester.pumpAndSettle();
      expect(store.tasksOf(day).single.title, 'Da Ana');
      await tester.pumpWidget(const SizedBox.shrink());
      // O app remove seu listener, mas não descarta serviços recebidos de fora.
      auth.logout();
      expect(store.tasksOf(day).single.title, 'Da Ana');
      store.add(day, 'Após desmontar');
      expect(store.tasksOf(day), hasLength(2));
    },
  );

  testWidgets(
    'trocar serviços injetados desconecta os antigos e usa os novos',
    (tester) async {
      final firstAuth = AuthService();
      final secondAuth = AuthService();
      final firstStore = TaskStore();
      final secondStore = TaskStore();
      addTearDown(firstAuth.dispose);
      addTearDown(secondAuth.dispose);
      addTearDown(firstStore.dispose);
      addTearDown(secondStore.dispose);
      firstAuth.register('ana@example.com', '123456');
      firstAuth.login('ana@example.com', '123456');
      secondAuth.register('bia@example.com', '123456');
      secondAuth.login('bia@example.com', '123456');
      final day = DateTime(2026, 11, 10);
      await tester.pumpWidget(
        MeuPlannerApp(authService: firstAuth, taskStore: firstStore),
      );
      firstStore.add(day, 'Primeiro');
      await tester.pumpWidget(
        MeuPlannerApp(authService: secondAuth, taskStore: secondStore),
      );
      await tester.pumpAndSettle();
      final screen = tester.widget<CalendarScreen>(find.byType(CalendarScreen));
      expect(screen.authService, same(secondAuth));
      expect(screen.taskStore, same(secondStore));
      secondStore.add(day, 'Segundo');
      firstAuth.logout();
      expect(firstStore.tasksOf(day).single.title, 'Primeiro');
      expect(secondStore.tasksOf(day).single.title, 'Segundo');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
