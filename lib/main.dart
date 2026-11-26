import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth_screen.dart';
import 'screens/calendar_screen.dart';
import 'services/auth_service.dart';
import 'stores/task_store.dart';
import 'theme.dart';

void main() => runApp(const MeuPlannerApp());

class MeuPlannerApp extends StatefulWidget {
  const MeuPlannerApp({super.key, this.authService, this.taskStore});

  final AuthService? authService;
  final TaskStore? taskStore;

  @override
  State<MeuPlannerApp> createState() => _MeuPlannerAppState();
}

class _MeuPlannerAppState extends State<MeuPlannerApp> {
  late AuthService _authService;
  late TaskStore _taskStore;

  @override
  void initState() {
    super.initState();
    _connectServices();
  }

  void _connectServices() {
    _authService = widget.authService ?? AuthService();
    _taskStore = widget.taskStore ?? TaskStore();
    _syncOwner();
    _authService.addListener(_syncOwner);
  }

  void _syncOwner() => _taskStore.useOwner(_authService.currentEmail);

  void _disconnectServices(MeuPlannerApp configuration) {
    _authService.removeListener(_syncOwner);
    // Serviços fornecidos por quem criou o app continuam sob sua responsabilidade.
    if (configuration.authService == null) _authService.dispose();
    if (configuration.taskStore == null) _taskStore.dispose();
  }

  @override
  void didUpdateWidget(covariant MeuPlannerApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authService != widget.authService ||
        oldWidget.taskStore != widget.taskStore) {
      _authService.removeListener(_syncOwner);
      if (oldWidget.authService != widget.authService) {
        if (oldWidget.authService == null) _authService.dispose();
        _authService = widget.authService ?? AuthService();
      }
      if (oldWidget.taskStore != widget.taskStore) {
        if (oldWidget.taskStore == null) _taskStore.dispose();
        _taskStore = widget.taskStore ?? TaskStore();
      }
      _syncOwner();
      _authService.addListener(_syncOwner);
    }
  }

  @override
  void dispose() {
    _disconnectServices(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu Planner',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Escuta o login: logou -> calendário, saiu -> tela de login.
      home: ListenableBuilder(
        listenable: _authService,
        builder: (context, _) => _authService.isLoggedIn
            ? CalendarScreen(authService: _authService, taskStore: _taskStore)
            : AuthScreen(authService: _authService),
      ),
    );
  }
}
