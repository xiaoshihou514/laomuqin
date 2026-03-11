import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../data/models/chat_message.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_page.dart';
import '../settings/settings_viewmodel.dart';
import 'main_viewmodel.dart';
import 'widgets/asr_recording_sheet.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/timer_card.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MainView();
  }
}

class _MainView extends StatefulWidget {
  const _MainView();

  @override
  State<_MainView> createState() => _MainViewState();
}

class _MainViewState extends State<_MainView> {
  final _scrollController = ScrollController();
  late final TextEditingController _inputController;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend(BuildContext context, String text) {
    final vm = context.read<MainViewModel>();
    final l10n = AppLocalizations.of(context)!;

    vm.submitTask.execute(text).then((_) {
      final promptId = vm.addDeadlinePrompt(l10n.mainSetDeadline);
      vm.addDeadlinePromptWidget(
        _DeadlineActions(
          messageId: promptId,
          taskTitle: text,
          l10n: l10n,
          viewModel: vm,
        ),
        promptId,
      );
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  Future<void> _onMicTap(BuildContext context) async {
    final vm = context.read<MainViewModel>();
    final l10n = AppLocalizations.of(context)!;

    final settingsJson = vm.asrModelSettingsJson;
    if (settingsJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.asrModelNotConfigured)),
      );
      return;
    }

    final transcript = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AsrRecordingSheet(settingJson: settingsJson),
    );

    if (transcript != null && transcript.isNotEmpty) {
      _inputController.text = transcript;
    }
  }

  Future<void> _onStartTimer(BuildContext context) async {
    final vm = context.read<MainViewModel>();
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();

    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => TDInputDialog(
        textEditingController: nameCtrl,
        title: l10n.mainStartTimerTitle,
        hintText: l10n.mainStartTimerHint,
        leftBtn: TDDialogButtonOptions(
          title: l10n.mainStartTimerCancel,
          action: () => Navigator.pop(ctx),
        ),
        rightBtn: TDDialogButtonOptions(
          title: l10n.mainStartTimerConfirm,
          action: () => Navigator.pop(ctx, nameCtrl.text),
        ),
      ),
    );

    nameCtrl.dispose();
    if (title != null && title.trim().isNotEmpty) {
      vm.startTask.execute(title.trim());
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final vm = context.watch<MainViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<SettingsViewModel>(),
                    child: const SettingsPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat list
          Expanded(
            child: ListenableBuilder(
              listenable: vm,
              builder: (_, _) {
                final messages = vm.messages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (msg.type == ChatMessageType.timer) {
                      return _TimerMessageItem(
                        message: msg,
                        viewModel: vm,
                      );
                    }
                    return ChatBubble(message: msg);
                  },
                );
              },
            ),
          ),
          // Big action buttons — always visible regardless of ASR setting
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TDButton(
                    icon: TDIcons.help_circle,
                    text: l10n.mainAskTasksBtn,
                    type: TDButtonType.fill,
                    size: TDButtonSize.large,
                    isBlock: true,
                    style: TDButtonStyle(
                      backgroundColor: colorScheme.secondaryContainer,
                      textColor: colorScheme.onSecondaryContainer,
                    ),
                    onTap: () {
                      vm.askTasks.execute();
                      _scrollToBottom();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TDButton(
                    icon: TDIcons.play_circle,
                    text: l10n.mainStartTimerBtn,
                    type: TDButtonType.fill,
                    theme: TDButtonTheme.primary,
                    size: TDButtonSize.large,
                    isBlock: true,
                    onTap: () => _onStartTimer(context),
                  ),
                ),
              ],
            ),
          ),
          // Input bar — layout changes based on ASR
          ListenableBuilder(
            listenable: vm,
            builder: (_, _) => ChatInputBar(
              controller: _inputController,
              asrEnabled: vm.asrEnabled,
              onSend: (text) => _onSend(context, text),
              onMicTap: () => _onMicTap(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineActions extends StatefulWidget {
  const _DeadlineActions({
    required this.messageId,
    required this.taskTitle,
    required this.l10n,
    required this.viewModel,
  });

  final String messageId;
  final String taskTitle;
  final AppLocalizations l10n;
  final MainViewModel viewModel;

  @override
  State<_DeadlineActions> createState() => _DeadlineActionsState();
}

class _DeadlineActionsState extends State<_DeadlineActions> {
  DateTime? _pickedDeadline;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;

    final deadline = pickedTime != null
        ? DateTime(picked.year, picked.month, picked.day, pickedTime.hour,
            pickedTime.minute)
        : picked;

    setState(() => _pickedDeadline = deadline);
  }

  void _confirm(bool withAlarm) {
    final deadline = _pickedDeadline;
    widget.viewModel.removeInlineWidget(widget.messageId);
    widget.viewModel.confirmDeadline.execute((deadline, withAlarm));

    final formatted = deadline != null
        ? '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-'
            '${deadline.day.toString().padLeft(2, '0')} '
            '${deadline.hour.toString().padLeft(2, '0')}:'
            '${deadline.minute.toString().padLeft(2, '0')}'
        : null;

    final msg = formatted != null
        ? widget.l10n.mainTaskWithDeadline(widget.taskTitle, formatted)
        : widget.l10n.mainTaskConfirmed(widget.taskTitle);
    widget.viewModel.addConfirmationMessage(msg);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    // Step 2: deadline picked — ask about alarm
    if (_pickedDeadline != null) {
      return Row(
        children: [
          Expanded(
            child: TDButton(
              text: l10n.mainSetAlarm,
              type: TDButtonType.fill,
              theme: TDButtonTheme.primary,
              size: TDButtonSize.medium,
              isBlock: true,
              onTap: () => _confirm(true),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TDButton(
              text: l10n.mainNoAlarm,
              type: TDButtonType.outline,
              size: TDButtonSize.medium,
              isBlock: true,
              style: TDButtonStyle(
                textColor: colorScheme.onSurface,
                frameColor: colorScheme.outlineVariant,
                backgroundColor: Colors.transparent,
              ),
              onTap: () => _confirm(false),
            ),
          ),
        ],
      );
    }

    // Step 1: ask whether to set deadline
    return Row(
      children: [
        Expanded(
          child: TDButton(
            icon: Icons.calendar_today_outlined,
            text: l10n.mainDeadlineButton,
            type: TDButtonType.outline,
            size: TDButtonSize.medium,
            isBlock: true,
            style: TDButtonStyle(
              textColor: colorScheme.onSurface,
              frameColor: colorScheme.outline,
              backgroundColor: Colors.transparent,
            ),
            onTap: _pickDeadline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TDButton(
            icon: Icons.not_interested_outlined,
            text: l10n.mainDeadlineSkip,
            type: TDButtonType.outline,
            size: TDButtonSize.medium,
            isBlock: true,
            style: TDButtonStyle(
              textColor: colorScheme.onSurfaceVariant,
              frameColor: colorScheme.outlineVariant,
              backgroundColor: Colors.transparent,
            ),
            onTap: () => _confirm(false),
          ),
        ),
      ],
    );
  }
}

class _TimerMessageItem extends StatelessWidget {
  const _TimerMessageItem({required this.message, required this.viewModel});

  final ChatMessage message;
  final MainViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final taskId = message.taskId ?? '';
    final l10n = AppLocalizations.of(context)!;

    if (message.content == l10n.timerStopped || message.content == '任务已结束') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(l10n.timerStopped),
        ),
      );
    }

    return TimerCard(
      taskTitle: taskId,
      onStop: () => viewModel.resolveTimerStop(taskId),
    );
  }
}

