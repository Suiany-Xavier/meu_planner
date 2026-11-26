import 'package:flutter_test/flutter_test.dart';
import 'package:meu_planner/services/auth_service.dart';
import 'package:meu_planner/stores/task_store.dart';

void main() {
  test('editar reordena o título sem alterar o ID ou o status', () {
    final store = TaskStore();
    addTearDown(store.dispose);
    final day = DateTime(2026, 11, 10);
    store.add(day, 'Zebra');
    store.add(day, 'Banana');
    final task = store.tasksOf(day).last;
    expect(store.update(day, task.id, title: ' Árvore '), isTrue);
    expect(store.tasksOf(day).first.title, 'Árvore');
    expect(store.tasksOf(day).first.id, task.id);
    expect(store.tasksOf(day).first.done, isFalse);
    store.toggle(day, task.id);
    expect(store.update(day, task.id, title: 'Concluída'), isTrue);
    expect(store.tasksOf(day).last.done, isTrue);
    expect(store.update(day, task.id, title: '  '), isFalse);
    expect(store.tasksOf(day).last.title, 'Concluída');
  });

  test('transferir preserva tarefas existentes, status e dono', () {
    final store = TaskStore();
    addTearDown(store.dispose);
    final source = DateTime(2026, 11, 10);
    final target = DateTime(2027, 1, 1);
    store.useOwner('ana@example.com');
    store.add(source, 'Transferir');
    store.add(target, 'Já estava aqui');
    final task = store.tasksOf(source).single;
    store.toggle(source, task.id);
    store.useOwner('bia@example.com');
    expect(store.update(source, task.id, targetDay: target), isFalse);
    store.useOwner('ana@example.com');
    expect(store.update(source, task.id, targetDay: target), isTrue);
    expect(store.tasksOf(source), isEmpty);
    expect(store.doneCount(source), 0);
    expect(store.pendingCount(target), 1);
    expect(store.doneCount(target), 1);
    expect(store.tasksOf(target).last.id, task.id);
    expect(store.tasksOf(target).last.title, 'Transferir');
    expect(store.update(target, task.id, targetDay: target), isTrue);
    expect(store.tasksOf(target), hasLength(2));
    expect(store.update(source, task.id, targetDay: target), isFalse);
  });

  test('cadastro valida os dados e login normaliza o e-mail', () {
    final auth = AuthService();
    addTearDown(auth.dispose);
    addTearDown(auth.logout);
    expect(auth.register('email-invalido', '123456'), isNotNull);
    expect(auth.register('ana@example.com', '123'), isNotNull);
    expect(auth.register(' Ana@Example.com ', '123456'), isNull);
    expect(auth.register('ana@example.com', '123456'), isNotNull);
    expect(auth.login('ana@example.com', 'errada'), isNotNull);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.login(' ANA@EXAMPLE.COM ', '123456'), isNull);
    expect(auth.displayName, 'Ana');
    auth.logout();
    expect(auth.isLoggedIn, isFalse);
  });

  test('tarefas respeitam dono, dia e ordenação por status e acento', () {
    final store = TaskStore();
    addTearDown(store.dispose);
    final day = DateTime(2026, 11, 10);
    final otherDay = DateTime(2026, 11, 11);
    store.useOwner('ana@example.com');
    store.add(day, 'Zebra');
    store.add(day, ' Árvore ');
    store.add(day, 'Banana');
    store.add(day, '  ');
    store.add(otherDay, 'Outro dia');
    expect(store.tasksOf(day).map((t) => t.title), [
      'Árvore',
      'Banana',
      'Zebra',
    ]);
    final task = store.tasksOf(day).first;
    store.toggle(day, task.id);
    expect(store.tasksOf(day).map((t) => t.title), [
      'Banana',
      'Zebra',
      'Árvore',
    ]);
    expect(store.pendingCount(day), 2);
    expect(store.doneCount(day), 1);
    final completed = store.tasksOf(day).last;
    store.remove(day, task.id);
    store.restore(day, completed);
    expect(store.doneCount(day), 1);
    expect(store.tasksOf(otherDay).single.title, 'Outro dia');
    store.useOwner('bia@example.com');
    expect(store.tasksOf(day), isEmpty);
    store.add(day, 'Da Bia');
    store.useOwner('ana@example.com');
    expect(store.tasksOf(day), hasLength(3));
    expect(store.tasksOf(day).last.done, isTrue);
  });
}
