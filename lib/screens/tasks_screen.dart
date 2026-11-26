import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/auth_service.dart';
import '../stores/task_store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'add_task_dialog.dart';

enum _TaskAction { edit, move, remove }

class TasksScreen extends StatelessWidget {
  const TasksScreen({
    super.key,
    required this.day,
    required this.authService,
    required this.taskStore,
    this.embedded = false,
    this.onOpenDay,
  });

  final AuthService authService;
  final TaskStore taskStore;

  final DateTime day;
  final bool embedded;
  final ValueChanged<DateTime>? onOpenDay;

  Future<void> _addTask(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => const AddTaskDialog(),
    );
    if (!context.mounted) return;
    if (title != null) taskStore.add(day, title);
  }

  Future<void> _editTask(BuildContext context, Task task) async {
    final owner = authService.currentEmail;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => AddTaskDialog(initialTitle: task.title),
    );
    if (!context.mounted ||
        owner != authService.currentEmail ||
        title == null) {
      return;
    }
    taskStore.update(day, task.id, title: title);
  }

  Future<void> _moveTask(BuildContext context, Task task) async {
    final owner = authService.currentEmail;
    final targetDay = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      helpText: 'Transferir tarefa',
      confirmText: 'Transferir',
    );
    if (!context.mounted ||
        owner != authService.currentEmail ||
        targetDay == null) {
      return;
    }
    if (isSameDay(day, targetDay)) return;
    if (!taskStore.update(day, task.id, targetDay: targetDay)) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Tarefa transferida para ${formatDate(targetDay)}.'),
          persist: false,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'ABRIR',
            onPressed: () {
              if (!context.mounted || owner != authService.currentEmail) return;
              if (onOpenDay != null) {
                onOpenDay!(targetDay);
                return;
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => TasksScreen(
                    day: targetDay,
                    authService: authService,
                    taskStore: taskStore,
                  ),
                ),
              );
            },
          ),
        ),
      );
  }

  void _remove(BuildContext context, Task task) {
    final owner = authService.currentEmail;
    taskStore.remove(day, task.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${task.title}" removida'),
          persist: false,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'DESFAZER',
            onPressed: () {
              if (owner != authService.currentEmail) return;
              taskStore.restore(day, task);
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: embedded
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(20, 12, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: taskStore,
              builder: (context, _) {
                final tasks = taskStore.tasksOf(day);
                return CustomScrollView(
                  primary: false,
                  slivers: [
                    SliverToBoxAdapter(child: _header(context)),
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        top: 18,
                        right: 6,
                        bottom: 18,
                      ),
                      sliver: SliverToBoxAdapter(child: _summary(tasks)),
                    ),
                    _list(context, tasks),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: NeoButton(
              semanticLabel: 'Adicionar tarefa',
              color: AppColors.lime,
              radius: 40,
              padding: const EdgeInsets.all(14),
              onPressed: () => _addTask(context),
              child: embedded
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: AppColors.ink),
                        SizedBox(width: 8),
                        Text('Nova tarefa', style: AppText.button),
                      ],
                    )
                  : const Icon(
                      Icons.add_rounded,
                      size: 40,
                      color: AppColors.ink,
                    ),
            ),
          ),
        ],
      ),
    );
    if (embedded) return content;
    return Scaffold(
      body: BlobBackground(
        blobs: const [AppColors.cyan, AppColors.pink, AppColors.lime],
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: content,
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => embedded
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tarefas do dia', style: AppText.title),
            const SizedBox(height: 8),
            Text(
              'Dia ${formatDate(day)}',
              style: AppText.body.copyWith(color: AppColors.cyan),
            ),
          ],
        )
      : Row(
          children: [
            NeoButton(
              semanticLabel: 'Voltar ao calendário',
              color: Colors.white,
              radius: 16,
              shadow: 4,
              padding: const EdgeInsets.all(10),
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo, ${authService.displayName}!',
                    style: AppText.onBackground,
                  ),
                  Text(
                    'Dia ${formatDate(day)}',
                    style: AppText.title.copyWith(fontSize: 28),
                  ),
                ],
              ),
            ),
          ],
        );

  Widget _summary(List<Task> tasks) {
    final total = tasks.length;
    final done = tasks.where((t) => t.done).length;
    final pending = total - done;
    final progress = total == 0 ? 0.0 : done / total;

    return NeoBox(
      color: AppColors.yellow,
      radius: 20,
      shadow: 4,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0
                ? 'Dia livre por enquanto'
                : '$pending pendente${pending == 1 ? '' : 's'}  •  '
                      '$done concluída${done == 1 ? '' : 's'}',
            style: AppText.body,
          ),
          const SizedBox(height: 10),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.ink, width: 2.5),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 56,
              ),
              const SizedBox(height: 10),
              Text(
                'Nada por aqui ainda.\nBora adicionar a primeira?',
                textAlign: TextAlign.center,
                style: AppText.onBackground.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    // A lista já vem ordenada (pendentes -> concluídas, A-Z) do taskStore.
    // Aqui só intercalamos os títulos de seção.
    final pending = tasks.where((t) => !t.done).toList();
    final done = tasks.where((t) => t.done).toList();
    final items = <Object>[
      if (pending.isNotEmpty) 'EM ANDAMENTO',
      ...pending,
      if (done.isNotEmpty) 'CONCLUÍDAS',
      ...done,
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final item = items[i];
          if (item is String) {
            return Padding(
              key: ValueKey('section-$item'),
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            );
          }
          final task = item as Task;
          return _TaskTile(
            key: ValueKey(task.id),
            task: task,
            onRemove: (t) => _remove(context, t),
            onEdit: (t) => _editTask(context, t),
            onMove: (t) => _moveTask(context, t),
            onToggle: () => taskStore.toggle(day, task.id),
          );
        },
        childCount: items.length,
        findChildIndexCallback: (key) {
          final index = items.indexWhere(
            (item) => key == ValueKey(item is Task ? item.id : 'section-$item'),
          );
          return index < 0 ? null : index;
        },
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    super.key,
    required this.task,
    required this.onRemove,
    required this.onEdit,
    required this.onMove,
    required this.onToggle,
  });

  final Task task;
  final void Function(Task) onRemove;
  final void Function(Task) onEdit;
  final void Function(Task) onMove;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, bottom: 14),
      child: Dismissible(
        key: ValueKey(task.id),
        direction:
            DismissDirection.endToStart, // arrasta pra esquerda p/ remover
        onDismissed: (_) => onRemove(task),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.pink,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.ink, width: 3),
          ),
          child: const Icon(
            Icons.delete_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        child: NeoBox(
          color: task.done ? AppColors.lilac : Colors.white,
          radius: 20,
          shadow: 4,
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              AccessibleAction(
                label: task.title,
                checked: task.done,
                hint: task.done
                    ? 'Marcar como pendente'
                    : 'Marcar como concluída',
                onPressed: onToggle,
                builder: (context, focused) => SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: task.done ? AppColors.lime : AppColors.cyan,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.ink, width: 3),
                        boxShadow: focused ? focusRing : const [],
                      ),
                      child: task.done
                          ? const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppColors.ink,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    task.title,
                    style: AppText.body.copyWith(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                      color: task.done ? AppColors.inkMuted : AppColors.ink,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<_TaskAction>(
                tooltip: 'Opções da tarefa: ${task.title}',
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
                onSelected: (action) {
                  switch (action) {
                    case _TaskAction.edit:
                      onEdit(task);
                    case _TaskAction.move:
                      onMove(task);
                    case _TaskAction.remove:
                      onRemove(task);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _TaskAction.edit,
                    child: Text('Editar tarefa'),
                  ),
                  PopupMenuItem(
                    value: _TaskAction.move,
                    child: Text('Transferir para outra data'),
                  ),
                  PopupMenuItem(
                    value: _TaskAction.remove,
                    child: Text('Excluir tarefa'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
