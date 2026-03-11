import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../main/main_page.dart';
import '../settings/asr_settings_page.dart';
import '../settings/settings_viewmodel.dart';
import 'setup_viewmodel.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.viewModel});

  final SetupViewModel viewModel;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    widget.viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    _pageController.dispose();
    widget.viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  void _onViewModelChange() {
    final index = widget.viewModel.stepIndex;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishAndNavigate(bool asrEnabled) async {
    await widget.viewModel.finishSetup.execute(asrEnabled);
    if (!mounted) return;

    if (asrEnabled) {
      // Let the user configure the ASR model before entering the main app.
      final settingsVm = context.read<SettingsViewModel>();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AsrSettingsPage(viewModel: settingsVm),
        ),
      );
      if (!mounted) return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.viewModel,
          builder: (context, _) {
            return Column(
              children: [
                _StepIndicator(
                  current: widget.viewModel.stepIndex,
                  total: widget.viewModel.totalSteps,
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomeStep(viewModel: widget.viewModel),
                      _NotificationStep(viewModel: widget.viewModel),
                      _BackgroundStep(viewModel: widget.viewModel),
                      _AsrStep(onFinish: _finishAndNavigate),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(total, (i) {
          final isActive = i <= current;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({required this.viewModel});

  final SetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StepScaffold(
      iconWidget: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset('assets/icon.png', width: 100, height: 100),
      ),
      title: l10n.setupWelcomeTitle,
      description: l10n.setupWelcomeSubtitle,
      primaryLabel: l10n.setupWelcomeButton,
      onPrimary: () => viewModel.nextStep.execute(),
    );
  }
}

class _NotificationStep extends StatelessWidget {
  const _NotificationStep({required this.viewModel});

  final SetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StepScaffold(
      iconWidget: Icon(
        TDIcons.notification,
        size: 80,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: l10n.setupNotificationTitle,
      description: l10n.setupNotificationDesc,
      primaryLabel: l10n.setupNotificationGrant,
      secondaryLabel: l10n.setupSkip,
      onPrimary: () => viewModel.requestNotification.execute(),
      onSecondary: () => viewModel.nextStep.execute(),
    );
  }
}

class _BackgroundStep extends StatelessWidget {
  const _BackgroundStep({required this.viewModel});

  final SetupViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StepScaffold(
      iconWidget: Icon(
        TDIcons.play_circle,
        size: 80,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: l10n.setupBackgroundTitle,
      description: l10n.setupBackgroundDesc,
      primaryLabel: l10n.setupBackgroundGrant,
      secondaryLabel: l10n.setupSkip,
      onPrimary: () => viewModel.requestBackground.execute(),
      onSecondary: () => viewModel.nextStep.execute(),
    );
  }
}

class _AsrStep extends StatelessWidget {
  const _AsrStep({required this.onFinish});

  final Future<void> Function(bool) onFinish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StepScaffold(
      iconWidget: Icon(
        TDIcons.microphone,
        size: 80,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: l10n.setupAsrTitle,
      description: l10n.setupAsrDesc,
      primaryLabel: l10n.setupAsrEnable,
      secondaryLabel: l10n.setupAsrSkip,
      onPrimary: () => onFinish(true),
      onSecondary: () => onFinish(false),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.iconWidget,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final Widget iconWidget;
  final String title;
  final String description;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: iconWidget),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 48),
          TDButton(
            text: primaryLabel,
            type: TDButtonType.fill,
            theme: TDButtonTheme.primary,
            size: TDButtonSize.large,
            isBlock: true,
            onTap: onPrimary,
          ),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 12),
            TDButton(
              text: secondaryLabel!,
              type: TDButtonType.text,
              theme: TDButtonTheme.defaultTheme,
              size: TDButtonSize.large,
              isBlock: true,
              onTap: onSecondary,
            ),
          ],
        ],
      ),
    );
  }
}
