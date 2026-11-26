import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Senha guardada como hash SHA-256 + salt aleatório (nunca em texto puro).
class _Credential {
  _Credential(this.salt, this.hash);

  final String salt;
  final String hash;
}

/// Autenticação de demonstração em memória, independente do armazenamento.
class AuthService extends ChangeNotifier {
  final Map<String, _Credential> _users = {}; // email -> credencial
  final Random _random = Random.secure();
  String? _currentEmail;

  bool get isLoggedIn => _currentEmail != null;
  String? get currentEmail => _currentEmail;

  /// "mateus.silva@x.com" -> "Mateus"
  String get displayName {
    final email = _currentEmail;
    if (email == null) return 'Você';
    final match = RegExp(r'^[A-Za-zÀ-ÿ]+').firstMatch(email);
    if (match == null) return 'Você';
    final name = match.group(0)!;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  String _newSalt() =>
      base64Encode(List<int>.generate(16, (_) => _random.nextInt(256)));

  String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  /// Devolve a mensagem de erro, ou null se deu tudo certo.
  String? register(String email, String password) {
    final e = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      return 'Digite um e-mail válido.';
    }
    if (password.trim().isEmpty || password.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }
    if (_users.containsKey(e)) return 'Esse e-mail já está cadastrado.';
    final salt = _newSalt();
    _users[e] = _Credential(salt, _hash(salt, password));
    return null;
  }

  String? login(String email, String password) {
    final e = email.trim().toLowerCase();
    if (e.isEmpty || password.isEmpty) return 'Preencha e-mail e senha.';
    final credential = _users[e];
    if (credential == null ||
        credential.hash != _hash(credential.salt, password)) {
      return 'E-mail ou senha incorretos.';
    }
    _currentEmail = e;
    notifyListeners();
    return null;
  }

  void logout() {
    _currentEmail = null;
    notifyListeners();
  }
}
