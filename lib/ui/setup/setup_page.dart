import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../main/main_page.dart';
import 'setup_viewmodel.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key, required this.viewModel});

  final SetupViewModel viewModel;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with WidgetsBindingObserver {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    widget.viewModel.addListener(_onViewModelChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    widget.viewModel.removeListener(_onViewModelChange);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        widget.viewModel.currentStep == SetupStep.usageAccess) {
      widget.viewModel.checkUsageAccess.execute().then((_) {
        if (mounted && widget.viewModel.usageAccessGranted) {
          _finishAndNavigate();
        }
      });
    }
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

  Future<void> _finishAndNavigate() async {
    await widget.viewModel.finishSetup.execute();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainPage()),
    );
  }

  Future<void> _requestBackgroundAndProceed() async {
    await widget.viewModel.requestBackground.execute();
  }

  Future<void> _openUsageAccess() async {
    await widget.viewModel.openUsageAccess.execute();
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
                      _BackgroundStep(
                        onGrant: _requestBackgroundAndProceed,
                        onSkip: () => widget.viewModel.nextStep.execute(),
                      ),
                      _UsageAccessStep(
                        onGrant: _openUsageAccess,
                        onSkip: _finishAndNavigate,
                      ),
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
  const _BackgroundStep({required this.onGrant, required this.onSkip});

  final Future<void> Function() onGrant;
  final Future<void> Function() onSkip;

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
      onPrimary: () => onGrant(),
      onSecondary: () => onSkip(),
    );
  }
}

class _UsageAccessStep extends StatelessWidget {
  const _UsageAccessStep({required this.onGrant, required this.onSkip});

  final Future<void> Function() onGrant;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _StepScaffold(
      iconWidget: Icon(
        Icons.insights_outlined,
        size: 80,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: l10n.setupUsageAccessTitle,
      description: l10n.setupUsageAccessDesc,
      primaryLabel: l10n.setupUsageAccessGrant,
      secondaryLabel: l10n.setupSkip,
      onPrimary: () => onGrant(),
      onSecondary: () => onSkip(),
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
