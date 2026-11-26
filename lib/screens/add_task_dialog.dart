import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

/// Abre com `showDialog<String>()` e devolve o texto digitado (ou null se cancelar).
class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key, this.initialTitle});

  final String? initialTitle;

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Escreva o nome da tarefa primeiro 😉');
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      constraints: const BoxConstraints(maxWidth: 480),
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.only(right: 6, bottom: 6),
        child: SingleChildScrollView(
          child: NeoBox(
            color: AppColors.yellow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.initialTitle == null ? 'Nova tarefa' : 'Editar tarefa',
                  style: AppText.title.copyWith(
                    color: AppColors.ink,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 16),
                NeoField(
                  label: 'O que vamos fazer?',
                  controller: _controller,
                  autofocus: true,
                  fill: Colors.white,
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    liveRegion: true,
                    child: Text(_error!, style: AppText.error),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: NeoButton(
                        expand: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: AppText.button),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeoButton(
                        expand: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                        color: AppColors.pink,
                        onPressed: _submit,
                        child: Text(
                          widget.initialTitle == null ? 'Adicionar' : 'Salvar',
                          style: AppText.button.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
