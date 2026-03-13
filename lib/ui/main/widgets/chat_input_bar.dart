import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../l10n/app_localizations.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(ChatInputBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _send() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    widget.controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _TextInputRow(
          controller: widget.controller,
          colorScheme: colorScheme,
          l10n: l10n,
          hasText: _hasText,
          onSend: _send,
        ),
      ),
    );
  }
}

class _TextInputRow extends StatelessWidget {
  const _TextInputRow({
    required this.controller,
    required this.colorScheme,
    required this.l10n,
    required this.hasText,
    required this.onSend,
  });

  final TextEditingController controller;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;
  final bool hasText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TDInput(
            controller: controller,
            hintText: l10n.mainInputHint,
            backgroundColor: colorScheme.surfaceContainerHighest,
            textStyle: TextStyle(color: colorScheme.onSurface),
            hintTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            cursorColor: colorScheme.primary,
            onSubmitted: (_) => onSend(),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            TDIcons.send,
            color: hasText ? colorScheme.primary : colorScheme.outline,
          ),
          onPressed: hasText ? onSend : null,
        ),
      ],
    );
  }
}
