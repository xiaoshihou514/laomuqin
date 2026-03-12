import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

import '../models/asr_setting.dart';

// Top-level function required by compute() — runs in a fresh isolate each
// call, matching the proven pattern in jiyi's Speech.fromWAV implementation.
Future<String> _transcribeAudio(Map<String, dynamic> params) async {
  // Required for background isolates to access Flutter plugin channels.
  BackgroundIsolateBinaryMessenger.ensureInitialized(
    params['token'] as RootIsolateToken,
  );
  // Load native sherpa-onnx bindings (fast, idempotent).
  so.initBindings();

  final setting = AsrSetting.fromJson(params['settingJson'] as String);
  final samples = params['samples'] as Float32List;
  final sampleRate = params['sampleRate'] as int;

  // Fresh recognizer + fresh stream per call — no state contamination.
  final recognizer = so.OnlineRecognizer(
    so.OnlineRecognizerConfig(model: setting.model),
  );
  final stream = recognizer.createStream();

  // Do NOT call inputFinished() — jiyi never does.
  stream.acceptWaveform(samples: samples, sampleRate: sampleRate);
  while (recognizer.isReady(stream)) {
    recognizer.decode(stream);
  }
  final text = recognizer.getResult(stream).text;

  stream.free();
  recognizer.free();
  return text;
}

/// Transcribes [samples] (f32le PCM, mono at [sampleRate] Hz) using a fresh
/// background isolate via [compute]. Matches the jiyi reference implementation.
Future<String> transcribeAudio({
  required String settingJson,
  required Float32List samples,
  required int sampleRate,
}) {
  return compute(_transcribeAudio, {
    'token': ServicesBinding.rootIsolateToken!,
    'settingJson': settingJson,
    'samples': samples,
    'sampleRate': sampleRate,
  });
}
