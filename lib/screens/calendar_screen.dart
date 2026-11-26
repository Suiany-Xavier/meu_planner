import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../stores/task_store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'tasks_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.authService,
    required this.taskStore,
  });

  final AuthService authService;
  final TaskStore taskStore;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  AuthService get authService => widget.authService;
  TaskStore get taskStore => widget.taskStore;
  static const _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  static const _weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  static const _weekdayNames = [
    'Domingo',
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
  ];

  late DateTime _month; // sempre o dia 1 do mês que está na tela
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  // DateTime "normaliza" sozinho: mês 13 vira janeiro do ano seguinte.
  void _changeMonth(int delta) {
    _selectMonth(DateTime(_month.year, _month.month + delta));
  }

  void _selectMonth(DateTime month) {
    if (month.year < 1 || month.year > 9999) return;
    setState(() {
      _month = DateTime(month.year, month.month);
      final lastDay = DateTime(_month.year, _month.month + 1, 0).day;
      _selected = DateTime(
        _month.year,
        _month.month,
        _selected.day > lastDay ? lastDay : _selected.day,
      );
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selected = DateTime(now.year, now.month, now.day);
      _month = DateTime(now.year, now.month);
    });
  }

  Future<void> _pickMonth() async {
    final month = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthYearDialog(initialMonth: _month),
    );
    if (!mounted || month == null) return;
    _selectMonth(month);
  }

  void _open(DateTime day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TasksScreen(
          day: day,
          authService: authService,
          taskStore: taskStore,
        ),
      ),
    );
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selected = DateTime(day.year, day.month, day.day);
      _month = DateTime(day.year, day.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale =
                        MediaQuery.textScalerOf(context).scale(16) / 16;
                    final desktop = constraints.maxWidth >= 1100 * textScale;
                    if (!desktop) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _calendarPane(),
                        ),
                      );
                    }
                    return Row(
                      key: const ValueKey('desktop-planner'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: FocusTraversalGroup(
                            child: _calendarPane(desktop: true),
                          ),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          flex: 7,
                          child: FocusTraversalGroup(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: 6,
                                bottom: 6,
                              ),
                              child: NeoBox(
                                color: AppColors.blue,
                                child: TasksScreen(
                                  key: ValueKey(_selected),
                                  day: _selected,
                                  authService: authService,
                                  taskStore: taskStore,
                                  embedded: true,
                                  onOpenDay: _selectDay,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendarPane({bool desktop = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: SingleChildScrollView(
          primary: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6),
                child: ListenableBuilder(
                  listenable: taskStore,
                  builder: (context, _) => _calendarCard(desktop: desktop),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'Data selecionada: ${formatDate(_selected)}',
        textAlign: TextAlign.center,
        style: AppText.onBackground,
      ),
      if (!desktop) ...[
        const SizedBox(height: 8),
        NeoButton(
          key: const ValueKey('open-selected-day'),
          semanticLabel: 'Abrir tarefas de ${formatDate(_selected)}',
          expand: true,
          onPressed: () => _open(_selected),
          child: Text(
            'Abrir tarefas de ${formatDate(_selected).substring(0, 5)}',
            textAlign: TextAlign.center,
            style: AppText.button,
          ),
        ),
      ],
    ],
  );

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bem-vindo,', style: AppText.title),
              Text(
                '${authService.displayName}!',
                style: AppText.title.copyWith(color: AppColors.yellow),
              ),
            ],
          ),
        ),
        NeoButton(
          semanticLabel: 'Sair',
          color: Colors.white,
          radius: 16,
          shadow: 4,
          padding: const EdgeInsets.all(10),
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            authService.logout();
          },
          child: const Icon(Icons.logout_rounded, color: AppColors.ink),
        ),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return NeoButton(
      semanticLabel: icon == Icons.chevron_left_rounded
          ? 'Mês anterior'
          : 'Próximo mês',
      color: AppColors.cyan,
      radius: 12,
      shadow: 3,
      padding: const EdgeInsets.all(4),
      onPressed: onTap,
      child: Icon(icon, color: AppColors.ink, size: 26),
    );
  }

  Widget _calendarCard({required bool desktop}) {
    final first = DateTime(_month.year, _month.month, 1);
    final offset = first.weekday % 7; // domingo = 0, segunda = 1, ...
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

    return NeoBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              _arrow(Icons.chevron_left_rounded, () => _changeMonth(-1)),
              Expanded(
                child: Tooltip(
                  message: 'Escolher mês e ano',
                  child: TextButton(
                    onPressed: _pickMonth,
                    child: Text(
                      '${_months[_month.month - 1]} ${_month.year}',
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              _arrow(Icons.chevron_right_rounded, () => _changeMonth(1)),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _goToToday,
              icon: const Icon(Icons.today_rounded),
              label: const Text('Hoje'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < _weekdays.length; i++)
                Expanded(
                  child: Center(
                    child: Semantics(
                      label: _weekdayNames[i],
                      excludeSemantics: true,
                      child: Text(
                        _weekdays[i],
                        style: AppText.label.copyWith(color: AppColors.blue),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              mainAxisExtent: MediaQuery.textScalerOf(context).scale(15) + 36,
            ),
            itemCount: offset + daysInMonth,
            itemBuilder: (context, i) {
              if (i < offset) return const SizedBox.shrink(); // espaço vazio
              return _dayCell(
                DateTime(_month.year, _month.month, i - offset + 1),
                desktop: desktop,
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _dot(AppColors.cyan),
              const SizedBox(width: 4),
              const Text(
                'pendente',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 16),
              _dot(AppColors.lime),
              const SizedBox(width: 4),
              const Text(
                'concluída',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 9,
    height: 9,
    margin: const EdgeInsets.symmetric(horizontal: 1.5),
    decoration: BoxDecoration(
      color: c,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.ink, width: 1.2),
    ),
  );

  Widget _dayCell(DateTime day, {required bool desktop}) {
    final selected = isSameDay(day, _selected);
    final today = isSameDay(day, DateTime.now());
    final pending = taskStore.pendingCount(day);
    final done = taskStore.doneCount(day);

    return AccessibleAction(
      key: ValueKey(day),
      label:
          '${day.day} de ${_months[day.month - 1].toLowerCase()} de ${day.year}'
          ', ${_weekdayNames[day.weekday % 7].toLowerCase()}'
          '${today ? ', hoje' : ''}. '
          '$pending ${pending == 1 ? 'tarefa pendente' : 'tarefas pendentes'}, '
          '$done ${done == 1 ? 'tarefa concluída' : 'tarefas concluídas'}.',
      selected: selected,
      hint: desktop
          ? 'Selecionar dia e mostrar suas tarefas ao lado.'
          : 'Selecionar dia. Use o botão Abrir tarefas para acessar a lista.',
      onPressed: () => _selectDay(day),
      onDoubleTap: () => desktop
          ? _selectDay(day)
          : _open(day), // atalho: toque duplo abre o dia
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.pink
              : today
              ? AppColors.yellow
              : AppColors.lilac,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ink, width: selected ? 3 : 1.5),
          boxShadow: [
            if (selected)
              const BoxShadow(color: AppColors.ink, offset: Offset(3, 3)),
            if (focused) ...focusRing,
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${day.day}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : AppColors.ink,
                ),
              ),
            ),
            if (pending + done > 0) ...[
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pending > 0) _dot(AppColors.cyan),
                    if (done > 0) _dot(AppColors.lime),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthYearDialog extends StatefulWidget {
  const _MonthYearDialog({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _yearController;
  late int _month;

  @override
  void initState() {
    super.initState();
    _month = widget.initialMonth.month;
    _yearController = TextEditingController(
      text: '${widget.initialMonth.year}',
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      DateTime(int.parse(_yearController.text.trim()), _month),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escolher mês e ano'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _month,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mês'),
                items: [
                  for (var month = 1; month <= 12; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(_CalendarScreenState._months[month - 1]),
                    ),
                ],
                onChanged: (month) {
                  if (month != null) setState(() => _month = month);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Ano'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  final year = int.tryParse(value?.trim() ?? '');
                  if (year == null || year < 1 || year > 9999) {
                    return 'Digite um ano entre 1 e 9999.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Ir para o mês')),
      ],
    );
  }
}
