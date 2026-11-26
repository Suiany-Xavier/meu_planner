import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';

void main() {
  final day = DateTime(2026, 11, 25);

  TaskStore newStore() {
    final store = TaskStore()..useOwner('ana@example.com');
    addTearDown(store.dispose);
    return store;
  }

  AuthService newAuth() {
    final auth = AuthService();
    addTearDown(auth.dispose);
    return auth;
  }

  test(
    'cadastro rejeita e-mail repetido com outra grafia e senha só de espaços',
    () {
      final auth = newAuth();
      expect(auth.register('ana@example.com', '      '), isNotNull);
      expect(auth.register('ana@example.com', '123456'), isNull);
      expect(
        auth.register(' ANA@Example.com ', 'outra-senha'),
        'Esse e-mail já está cadastrado.',
      );
    },
  );

  test('login pede os campos vazios e confere a senha pelo hash', () {
    final auth = newAuth();
    expect(auth.login('', ''), 'Preencha e-mail e senha.');
    expect(auth.login('ana@example.com', ''), 'Preencha e-mail e senha.');
    expect(auth.register('ana@example.com', 'segredo1'), isNull);
    expect(auth.register('bia@example.com', 'segredo1'), isNull);
    expect(auth.login('ana@example.com', 'segredo2'), isNotNull);
    expect(auth.login('ana@example.com', 'segredo1 '), isNotNull);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.login('bia@example.com', 'segredo1'), isNull);
    expect(auth.currentEmail, 'bia@example.com');
  });

  test('restaurar não duplica uma tarefa que já está no dia', () {
    final store = newStore();
    store.add(day, 'Estudar');
    final task = store.tasksOf(day).single;
    store.restore(day, task);
    expect(store.tasksOf(day), hasLength(1));
    store.remove(day, task.id);
    store.restore(day, task);
    store.restore(day, task);
    expect(store.tasksOf(day).single.id, task.id);
  });

  test('editar com título vazio ou ID inexistente não altera nada', () {
    final store = newStore();
    store.add(day, 'Estudar');
    final task = store.tasksOf(day).single;
    expect(store.update(day, task.id, title: '   '), isFalse);
    expect(store.update(day, 'id-inexistente', title: 'Outro'), isFalse);
    expect(store.update(DateTime(2026, 1, 1), task.id, title: 'X'), isFalse);
    expect(store.tasksOf(day).single.title, 'Estudar');
  });

  test('remover a última tarefa do dia zera os contadores', () {
    final store = newStore();
    store.add(day, 'Pendente');
    store.add(day, 'Feita');
    final done = store.tasksOf(day).firstWhere((t) => t.title == 'Feita');
    store.toggle(day, done.id);
    for (final task in store.tasksOf(day)) {
      store.remove(day, task.id);
    }
    expect(store.tasksOf(day), isEmpty);
    expect(store.pendingCount(day), 0);
    expect(store.doneCount(day), 0);
  });
}
