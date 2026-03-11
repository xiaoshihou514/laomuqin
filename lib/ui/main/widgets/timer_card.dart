import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../l10n/app_localizations.dart';

class TimerCard extends StatefulWidget {
  const TimerCard({super.key, required this.taskTitle, required this.onStop});

  final String taskTitle;
  final VoidCallback onStop;

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> {
  late final Stopwatch _stopwatch;
  Timer? _ticker;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        _stopwatch.start();
      } else {
        _stopwatch.stop();
      }
      _paused = !_paused;
    });
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elapsed = _stopwatch.elapsed;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.taskTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.timerElapsed(_format(elapsed)),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TDButton(
                text: _paused ? l10n.timerResume : l10n.timerPause,
                type: TDButtonType.outline,
                theme: TDButtonTheme.primary,
                size: TDButtonSize.small,
                onTap: _togglePause,
              ),
              const SizedBox(width: 8),
              TDButton(
                text: l10n.timerStop,
                type: TDButtonType.fill,
                theme: TDButtonTheme.danger,
                size: TDButtonSize.small,
                onTap: widget.onStop,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
