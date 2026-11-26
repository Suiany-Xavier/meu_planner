import 'package:flutter/material.dart';

/// Paleta do app: azul de fundo + cores "neon" para dar vida.
class AppColors {
  /// Quase preto, usado nas bordas e sombras.
  static const ink = Color(0xFF1A0033);

  /// [ink] com 60% de opacidade, para o texto de tarefas concluídas.
  static const inkMuted = Color(0x991A0033);

  /// Azul do fundo das telas (também usado no ícone, na splash e na web).
  static const blue = Color(0xFF0821AF);

  /// Cor-base do ColorScheme do Material 3.
  static const seed = Color(0xFF2B4BFF);

  /// Fundo do Scaffold, visível só onde o BlobBackground não cobre.
  static const background = Color(0xFF2B2FFF);
  static const pink = Color(0xFFFF3D9A);
  static const cyan = Color(0xFF00E5FF);
  static const lime = Color(0xFFB6FF3B);
  static const yellow = Color(0xFFFFD60A);
  static const lilac = Color(0xFFF1E4FF);
}

class AppText {
  static const title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    height: 1.05,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: AppColors.ink,
  );
  static const body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  /// Texto branco direto sobre o fundo azul.
  static const onBackground = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
  );

  /// Mensagens de erro dos formulários.
  static const error = TextStyle(
    color: AppColors.pink,
    fontWeight: FontWeight.w900,
  );
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed),
    scaffoldBackgroundColor: AppColors.background,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.pink,
      selectionHandleColor: AppColors.pink,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
      actionTextColor: AppColors.lime,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
