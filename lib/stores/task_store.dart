import 'package:flutter/foundation.dart';

import '../models/task.dart';

/// Armazena e modifica tarefas em memória, separadas por usuário e dia.
class TaskStore extends ChangeNotifier {
  // dono (e-mail) -> dia ("2023-11-11") -> lista de tarefas
  final Map<String, Map<String, List<Task>>> _buckets = {};
  String _owner = '';
  int _counter = 0;

  Map<String, List<Task>> get _byDay => _buckets.putIfAbsent(_owner, () => {});

  /// Cada usuário enxerga só as próprias tarefas.
  void useOwner(String? email) {
    _owner = email ?? '';
    notifyListeners();
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Tira acento e põe em minúsculo, pra "Árvore" não ir parar depois do "Zebra".
  String _normalize(String s) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  /// REGRA DO TRABALHO: pendentes primeiro, concluídas depois,
  /// e dentro de cada grupo, ordem alfabética.
  List<Task> tasksOf(DateTime day) {
    final list = List<Task>.of(_byDay[_key(day)] ?? <Task>[]);
    list.sort((a, b) {
      if (a.done != b.done) return a.done ? 1 : -1; // pendente vem antes
      return _normalize(a.title).compareTo(_normalize(b.title));
    });
    return List<Task>.unmodifiable(list);
  }

  int pendingCount(DateTime day) =>
      (_byDay[_key(day)] ?? <Task>[]).where((t) => !t.done).length;

  int doneCount(DateTime day) =>
      (_byDay[_key(day)] ?? <Task>[]).where((t) => t.done).length;

  void add(DateTime day, String title) {
    final clean = title.trim();
    if (clean.isEmpty) return;
    final list = _byDay.putIfAbsent(_key(day), () => []);
    list.add(
      Task(
        id: '${DateTime.now().microsecondsSinceEpoch}-${_counter++}',
        title: clean,
      ),
    );
    notifyListeners();
  }

  void toggle(DateTime day, String id) {
    final list = _byDay[_key(day)];
    if (list == null) return;
    final index = list.indexWhere((task) => task.id == id);
    if (index == -1) return;
    final task = list[index];
    list[index] = task.copyWith(done: !task.done);
    notifyListeners();
  }

  /// Atualiza o título ou a data, mantendo a identidade e o status da tarefa.
  bool update(DateTime day, String id, {String? title, DateTime? targetDay}) {
    final clean = title?.trim();
    if (clean != null && clean.isEmpty) return false;
    final sourceKey = _key(day);
    final list = _byDay[sourceKey];
    if (list == null) return false;
    final index = list.indexWhere((task) => task.id == id);
    if (index == -1) return false;
    final task = list[index];
    final updated = task.copyWith(title: clean);
    final targetKey = _key(targetDay ?? day);
    if (targetKey == sourceKey) {
      list[index] = updated;
    } else {
      list.removeAt(index);
      if (list.isEmpty) _byDay.remove(sourceKey);
      _byDay.putIfAbsent(targetKey, () => []).add(updated);
    }
    notifyListeners();
    return true;
  }

  void remove(DateTime day, String id) {
    final list = _byDay[_key(day)];
    if (list == null) return;
    list.removeWhere((t) => t.id == id);
    if (list.isEmpty) _byDay.remove(_key(day));
    notifyListeners();
  }

  /// Usado pelo botão "DESFAZER" depois de remover.
  void restore(DateTime day, Task task) {
    final list = _byDay.putIfAbsent(_key(day), () => []);
    if (list.any((t) => t.id == task.id)) return; // já está lá: não duplica
    list.add(task);
    notifyListeners();
  }
}
