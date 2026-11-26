import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthService get authService => widget.authService;
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(bool login) => setState(() {
    _isLogin = login;
    _error = null;
  });

  void _submit() {
    final error = _isLogin
        ? authService.login(_email.text, _password.text)
        : authService.register(_email.text, _password.text);

    if (error != null) {
      setState(() => _error = error);
      return;
    }
    // Login OK: o main.dart troca de tela sozinho.
    // Cadastro OK: volta pra aba "Entrar".
    if (!_isLogin) {
      setState(() {
        _isLogin = true;
        _password.clear();
        _error = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada! Agora é só entrar 🎉')),
      );
    }
  }

  Widget _tab(String label, bool login) {
    final selected = _isLogin == login;
    return NeoButton(
      selected: selected,
      expand: true,
      shadow: selected ? 5 : 3,
      color: selected ? AppColors.lime : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: () => _setMode(login),
      child: Text(label, style: AppText.button.copyWith(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlobBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 30, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Transform.rotate(
                        angle: -0.12,
                        child: const NeoBox(
                          padding: EdgeInsets.all(14),
                          radius: 24,
                          child: Icon(
                            Icons.checklist_rounded,
                            size: 56,
                            color: AppColors.blue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Meu Planner',
                      textAlign: TextAlign.center,
                      style: AppText.title.copyWith(fontSize: 40),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suas tarefas, no seu ritmo.',
                      textAlign: TextAlign.center,
                      style: AppText.onBackground.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _tab('Entrar', true)),
                        const SizedBox(width: 12),
                        Expanded(child: _tab('Cadastrar', false)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    NeoBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          NeoField(
                            label: 'Email',
                            controller: _email,
                            keyboard: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          NeoField(
                            label: 'Senha',
                            controller: _password,
                            obscure: true,
                            onSubmitted: (_) => _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Semantics(
                              liveRegion: true,
                              child: Text(_error!, style: AppText.error),
                            ),
                          ],
                          const SizedBox(height: 18),
                          NeoButton(
                            expand: true,
                            color: AppColors.pink,
                            onPressed: _submit,
                            child: Text(
                              _isLogin ? 'Entrar' : 'Cadastrar',
                              style: AppText.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => _setMode(!_isLogin),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.blue,
                            ),
                            child: Text(
                              _isLogin
                                  ? 'Não é cadastrado? Cadastre-se'
                                  : 'Já tem conta? Entre',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
