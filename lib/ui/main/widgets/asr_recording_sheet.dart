import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import '../../../data/services/asr_service.dart';
import '../../../l10n/app_localizations.dart';

// Matches the jiyi reference SAMPLE_RATE constant.
// Not passed to _recorder.init() — device uses its own hardware default.
// This is the rate reported to sherpa-onnx acceptWaveform.
const _kSampleRate = 22050;

enum _RecordingState { idle, recording, processing }

class AsrRecordingSheet extends StatefulWidget {
  const AsrRecordingSheet({super.key, required this.settingJson});

  final String settingJson;

  @override
  State<AsrRecordingSheet> createState() => _AsrRecordingSheetState();
}

class _AsrRecordingSheetState extends State<AsrRecordingSheet> {
  final _recorder = Recorder.instance;

  _RecordingState _state = _RecordingState.idle;

  // Visualization — polled from recorder like jiyi's getVolume()
  double _amplitude = 0.0;
  Duration _elapsed = Duration.zero;
  DateTime? _recordingStart;
  Timer? _uiTimer;

  // Audio buffer — List<double> exactly like jiyi's _bytes field.
  // Populated only when _capturing == true.
  final List<double> _bytes = List.empty(growable: true);
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  /// Matches jiyi's _recorderInit() sequence exactly:
  ///   await init → start → subscribe to stream → startStreamingData
  /// Recording begins immediately; _capturing gates whether we buffer audio.
  Future<void> _initRecorder() async {
    // Safety-net: ensure microphone permission before init.
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      if (mounted) _showError('Microphone permission denied');
      return;
    }
    try {
      await _recorder.init(
        channels: RecorderChannels.mono,
        format: PCMFormat.f32le,
        sampleRate: _kSampleRate,
        // No explicit sampleRate — device uses its own hardware default.
      );
      _recorder.start();
    } catch (e) {
      if (mounted) _showError('$e');
      return;
    }
    // Subscribe BEFORE startStreamingData — no missed chunks (jiyi pattern).
    _recorder.uint8ListStream.listen((data) {
      if (_capturing) {
        _bytes.addAll(data.toF32List(from: PCMFormat.f32le));
      }
    });
    _recorder.startStreamingData();
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _recorder.stopStreamingData();
    _recorder.deinit();
    super.dispose();
  }

  // ── Recording ──────────────────────────────────────────────────────────────

  void _startRecording() {
    HapticFeedback.mediumImpact();
    _bytes.clear();
    _capturing = true;

    _recordingStart = DateTime.now();
    _uiTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      // Poll volume from recorder — same approach as jiyi's RecorderVizSource.
      final vol = ((_recorder.getVolumeDb() + 100) / 100).clamp(0.0, 1.0);
      setState(() {
        _amplitude = vol;
        _elapsed = DateTime.now().difference(_recordingStart!);
      });
    });

    setState(() => _state = _RecordingState.recording);
  }

  Future<void> _stopRecording() async {
    if (_state != _RecordingState.recording) return;
    HapticFeedback.lightImpact();

    _capturing = false;
    _uiTimer?.cancel();
    setState(() {
      _state = _RecordingState.processing;
      _amplitude = 0;
    });

    if (_bytes.isEmpty) {
      _showEmpty();
      return;
    }

    // Convert to Float32List exactly like jiyi: Float32List.fromList(_bytes)
    final allSamples = Float32List.fromList(_bytes);

    try {
      final text = await transcribeAudio(
        settingJson: widget.settingJson,
        samples: allSamples,
        sampleRate: _kSampleRate,
      );
      if (!mounted) return;
      if (text.trim().isEmpty) {
        _showEmpty();
      } else {
        Navigator.pop(context, text.trim());
      }
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  void _cancelRecording() {
    if (_state != _RecordingState.recording) return;
    HapticFeedback.lightImpact();
    _capturing = false;
    _bytes.clear();
    _uiTimer?.cancel();
    setState(() {
      _state = _RecordingState.idle;
      _amplitude = 0;
    });
  }

  void _showEmpty() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.asrRecordEmpty)));
    Navigator.pop(context);
  }

  void _showError(String msg) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.asrRecordMicError}: $msg')));
    Navigator.pop(context);
  }

  String _fmt(Duration d) {
    String z(int n) => n.toString().padLeft(2, '0');
    return '${z(d.inMinutes.remainder(60))}:${z(d.inSeconds.remainder(60))}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title row with cancel button
              Row(
                children: [
                  const Spacer(),
                  Text(
                    l10n.asrRecordTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TDButton(
                    text: l10n.asrRecordCancel,
                    type: TDButtonType.text,
                    size: TDButtonSize.small,
                    style: TDButtonStyle(
                      textColor: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Visualization area (fixed height to prevent layout jumps)
              SizedBox(
                height: 64,
                child: _state == _RecordingState.recording
                    ? _FrequencyBars(
                        amplitude: _amplitude,
                        color: colorScheme.error,
                      )
                    : _state == _RecordingState.processing
                    ? Center(
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 8),

              // Elapsed timer (only while recording)
              SizedBox(
                height: 28,
                child: _state == _RecordingState.recording
                    ? Text(
                        _fmt(_elapsed),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                              color: colorScheme.error,
                            ),
                      )
                    : null,
              ),

              const SizedBox(height: 24),

              // Hold-to-record mic button
              _MicButton(
                state: _state,
                primaryColor: colorScheme.primary,
                errorColor: colorScheme.error,
                onHoldStart: _startRecording,
                onHoldEnd: _stopRecording,
                onHoldCancel: _cancelRecording,
              ),

              const SizedBox(height: 16),

              // Hint label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  key: ValueKey(_state),
                  _state == _RecordingState.idle
                      ? l10n.asrRecordHold
                      : _state == _RecordingState.recording
                      ? l10n.asrRecordLive
                      : l10n.asrRecordProcessing,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mic button ──────────────────────────────────────────────────────────────

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.state,
    required this.primaryColor,
    required this.errorColor,
    required this.onHoldStart,
    required this.onHoldEnd,
    required this.onHoldCancel,
  });

  final _RecordingState state;
  final Color primaryColor;
  final Color errorColor;
  final VoidCallback onHoldStart;
  final Future<void> Function() onHoldEnd;
  final VoidCallback onHoldCancel;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween(
      begin: 0.95,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.state == _RecordingState.recording) {
      _pulseCtrl.repeat(reverse: true);
    } else {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.state == _RecordingState.recording;
    final isProcessing = widget.state == _RecordingState.processing;
    final color = isRecording ? widget.errorColor : widget.primaryColor;

    return GestureDetector(
      onTapDown: isProcessing ? null : (_) => widget.onHoldStart(),
      onTapUp: isProcessing ? null : (_) => widget.onHoldEnd(),
      onTapCancel: isProcessing ? null : widget.onHoldCancel,
      child: ScaleTransition(
        scale: _pulseAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: isRecording ? 0.15 : 0.08),
            border: Border.all(color: color, width: isRecording ? 3 : 2),
          ),
          child: Icon(
            isRecording ? TDIcons.microphone : TDIcons.microphone,
            size: 40,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Frequency bars ──────────────────────────────────────────────────────────

class _FrequencyBars extends StatelessWidget {
  const _FrequencyBars({required this.amplitude, required this.color});

  final double amplitude;
  final Color color;

  static const _kBarCount = 9;
  static const _kMaxHeight = 56.0;
  static const _kMinHeight = 4.0;
  static const _kWidth = 5.0;
  static const _kGap = 4.0;
  static const _kMults = [0.5, 0.75, 1.0, 0.8, 0.9, 0.65, 0.85, 0.7, 0.55];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_kBarCount, (i) {
        final h =
            _kMinHeight + (_kMaxHeight - _kMinHeight) * amplitude * _kMults[i];
        return Padding(
          padding: EdgeInsets.only(right: i < _kBarCount - 1 ? _kGap : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: _kWidth,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
