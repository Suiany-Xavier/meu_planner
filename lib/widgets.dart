import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';

/// Ação com foco, ativação por teclado e descrição para leitores de tela.
class AccessibleAction extends StatefulWidget {
  const AccessibleAction({
    super.key,
    required this.onPressed,
    required this.builder,
    this.label,
    this.hint,
    this.selected,
    this.checked,
    this.onDoubleTap,
    this.onHighlightChanged,
  });

  final VoidCallback onPressed;
  final Widget Function(BuildContext, bool focused) builder;
  final String? label;
  final String? hint;
  final bool? selected;
  final bool? checked;
  final VoidCallback? onDoubleTap;
  final ValueChanged<bool>? onHighlightChanged;

  @override
  State<AccessibleAction> createState() => _AccessibleActionState();
}

class _AccessibleActionState extends State<AccessibleAction> {
  final _focusNode = FocusNode();
  bool _showFocus = false;
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _focusChanged(bool focused) {
    setState(() => _focused = focused);
    if (focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        Scrollable.ensureVisible(context, alignment: 0.5);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: _focusNode,
      includeFocusSemantics: false,
      mouseCursor: SystemMouseCursors.click,
      onFocusChange: _focusChanged,
      onShowFocusHighlight: (value) => setState(() => _showFocus = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: Semantics(
        container: true,
        button: widget.checked == null,
        enabled: true,
        focusable: true,
        focused: _focused,
        selected: widget.selected,
        checked: widget.checked,
        label: widget.label,
        hint: widget.hint,
        excludeSemantics: widget.label != null,
        onTap: widget.onPressed,
        onFocus: _focusNode.requestFocus,
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => widget.onHighlightChanged?.call(true),
          onTapUp: (_) => widget.onHighlightChanged?.call(false),
          onTapCancel: () => widget.onHighlightChanged?.call(false),
          onTap: widget.onPressed,
          onDoubleTap: widget.onDoubleTap,
          child: widget.builder(context, _showFocus),
        ),
      ),
    );
  }
}

/// Contorno duplo que continua visível sobre fundos claros ou coloridos.
const focusRing = [
  BoxShadow(color: AppColors.ink, spreadRadius: 4),
  BoxShadow(color: Colors.white, spreadRadius: 2),
];

/// Caixa "neo-brutalista": borda grossa + sombra dura (sem blur).
class NeoBox extends StatelessWidget {
  const NeoBox({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
    this.shadow = 6,
    this.border = 3,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double shadow;
  final double border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.ink, width: border),
        boxShadow: [
          BoxShadow(color: AppColors.ink, offset: Offset(shadow, shadow)),
        ],
      ),
      child: child,
    );
  }
}

/// Botão que "afunda" quando você aperta (a sombra some e ele desce).
class NeoButton extends StatefulWidget {
  const NeoButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = AppColors.lime,
    this.radius = 18,
    this.shadow = 5,
    this.expand = false,
    this.semanticLabel,
    this.selected,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
  });

  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final double radius;
  final double shadow;
  final bool expand; // true = ocupa a largura toda
  final String? semanticLabel;
  final bool? selected;
  final EdgeInsetsGeometry padding;

  @override
  State<NeoButton> createState() => _NeoButtonState();
}

class _NeoButtonState extends State<NeoButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = _down ? 0.0 : widget.shadow;
    final button = AccessibleAction(
      label: widget.semanticLabel,
      selected: widget.selected,
      onPressed: widget.onPressed,
      onHighlightChanged: (value) => setState(() => _down = value),
      builder: (context, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(
          widget.shadow - s,
          widget.shadow - s,
          0,
        ),
        constraints: widget.expand
            ? const BoxConstraints(minWidth: double.infinity)
            : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: AppColors.ink, width: 3),
          boxShadow: [
            BoxShadow(color: AppColors.ink, offset: Offset(s, s)),
            if (focused) ...focusRing,
          ],
        ),
        child: widget.expand
            ? Center(heightFactor: 1, child: widget.child)
            : widget.child,
      ),
    );
    return widget.semanticLabel == null
        ? button
        : Tooltip(
            message: widget.semanticLabel!,
            excludeFromSemantics: true,
            child: button,
          );
  }
}

/// Campo de texto com rótulo em cima.
class NeoField extends StatelessWidget {
  const NeoField({
    super.key,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.autofocus = false,
    this.keyboard,
    this.onSubmitted,
    this.textInputAction,
    this.fill = AppColors.lilac,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final bool autofocus;
  final TextInputType? keyboard;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Color fill;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c, width: 3),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Text(label, style: AppText.label)),
        const SizedBox(height: 6),
        Semantics(
          label: label,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            autofocus: autofocus,
            keyboardType: keyboard,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            style: AppText.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: fill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: _border(AppColors.ink),
              enabledBorder: _border(AppColors.ink),
              focusedBorder: _border(AppColors.pink),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fundo colorido com "bolhas" decorativas atrás do conteúdo.
class BlobBackground extends StatelessWidget {
  const BlobBackground({
    super.key,
    required this.child,
    this.color = AppColors.blue,
    this.blobs = const [AppColors.pink, AppColors.cyan, AppColors.yellow],
  });

  final Widget child;
  final Color color;
  final List<Color> blobs;

  Widget _blob(double size, Color c) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: c,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.ink, width: 3),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Stack(
        children: [
          Positioned(top: -70, right: -50, child: _blob(200, blobs[0])),
          Positioned(top: 260, left: -70, child: _blob(120, blobs[1])),
          Positioned(bottom: -90, right: -30, child: _blob(200, blobs[2])),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
