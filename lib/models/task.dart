/// Uma tarefa imutável. Alterações são feitas pelo TaskStore.
class Task {
  const Task({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  Task copyWith({String? title, bool? done}) =>
      Task(id: id, title: title ?? this.title, done: done ?? this.done);
}
