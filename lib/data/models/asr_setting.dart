import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

/// Supported model types for sherpa-onnx online ASR.
const List<String> kAsrModelTypes = [
  'transducer',
  'paraformer',
  'zipformer2Ctc',
  'nemoCtc',
];

// ---------------------------------------------------------------------------
// Preset system
// ---------------------------------------------------------------------------

const _kGhBase =
    'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models';

/// A preset model configuration that can be downloaded automatically.
class AsrPreset {
  const AsrPreset({
    required this.id,
    required this.name,
    required this.desc,
    required this.modelType,
    required this.folderName,
    required this.archiveFile,
    required this.tokensFile,
    this.encoderFile,
    this.decoderFile,
    this.joinerFile,
    this.singleFile,
  });

  final String id;
  final String name;
  final String desc;
  final String modelType;

  /// Folder name inside the support directory after extraction.
  final String folderName;

  /// Archive file name (e.g. "model.tar.bz2").
  final String archiveFile;

  /// Relative path to tokens.txt inside the extracted folder.
  final String tokensFile;

  // Relative paths for model files inside the extracted folder.
  final String? encoderFile;
  final String? decoderFile;
  final String? joinerFile;
  final String? singleFile;

  bool get needsEncoder =>
      modelType == 'transducer' || modelType == 'paraformer';
  bool get needsDecoder =>
      modelType == 'transducer' || modelType == 'paraformer';
  bool get needsJoiner => modelType == 'transducer';
  bool get needsSingle =>
      modelType == 'zipformer2Ctc' || modelType == 'nemoCtc';

  /// GitHub release download URL (international).
  String get githubUrl => '$_kGhBase/$archiveFile';

  /// Whether the extracted model folder already exists in [destDir].
  bool isDownloaded(String destDir) {
    final folder = p.join(destDir, folderName);
    final tokenPath = p.join(folder, tokensFile);
    return File(tokenPath).existsSync();
  }

  /// Build an [AsrSetting] with absolute paths inside [destDir].
  AsrSetting buildSetting(String destDir) {
    final folder = p.join(destDir, folderName);
    return AsrSetting(
      modelType: modelType,
      tokens: p.join(folder, tokensFile),
      encoder: encoderFile != null ? p.join(folder, encoderFile!) : null,
      decoder: decoderFile != null ? p.join(folder, decoderFile!) : null,
      joiner: joinerFile != null ? p.join(folder, joinerFile!) : null,
      single: singleFile != null ? p.join(folder, singleFile!) : null,
      name: name,
    );
  }
}

/// Built-in preset model configurations.
const List<AsrPreset> kAsrPresets = [
  AsrPreset(
    id: 'zh_en_zipformer',
    name: '中英双语 Zipformer (推荐)',
    desc: '适合中英混合语音识别，均衡性能',
    modelType: 'transducer',
    folderName: 'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20',
    archiveFile:
        'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20.tar.bz2',
    encoderFile: 'encoder-epoch-99-avg-1.int8.onnx',
    decoderFile: 'decoder-epoch-99-avg-1.int8.onnx',
    joinerFile: 'joiner-epoch-99-avg-1.int8.onnx',
    tokensFile: 'tokens.txt',
  ),
  AsrPreset(
    id: 'zh_en_paraformer',
    name: '中英双语 Paraformer',
    desc: '非自回归架构，速度更快',
    modelType: 'paraformer',
    folderName: 'sherpa-onnx-streaming-paraformer-bilingual-zh-en',
    archiveFile: 'sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2',
    encoderFile: 'encoder.onnx',
    decoderFile: 'decoder.onnx',
    tokensFile: 'tokens.txt',
  ),
  AsrPreset(
    id: 'zh_zipformer2ctc',
    name: '纯中文 Zipformer CTC',
    desc: '中文专用模型，准确度更高',
    modelType: 'zipformer2Ctc',
    folderName: 'sherpa-onnx-streaming-zipformer-ctc-zh-xlarge-int8-2025-06-30',
    archiveFile:
        'sherpa-onnx-streaming-zipformer-ctc-zh-xlarge-int8-2025-06-30.tar.bz2',
    singleFile: 'model.int8.onnx',
    tokensFile: 'tokens.txt',
  ),
  AsrPreset(
    id: 'en_nemo',
    name: '英文 NeMo CTC',
    desc: '英语专用轻量模型',
    modelType: 'nemoCtc',
    folderName: 'sherpa-onnx-nemo-ctc-en-conformer-small',
    archiveFile: 'sherpa-onnx-nemo-ctc-en-conformer-small.tar.bz2',
    singleFile: 'model.int8.onnx',
    tokensFile: 'tokens.txt',
  ),
];

// ---------------------------------------------------------------------------
// AsrSetting — persisted model configuration
// ---------------------------------------------------------------------------

class AsrSetting {
  AsrSetting({
    this.encoder,
    this.decoder,
    this.joiner,
    this.single,
    required this.tokens,
    required this.modelType,
    this.name,
  });

  String? encoder;
  String? decoder;
  String? joiner;
  String? single;
  String tokens;
  String modelType;
  String? name;

  factory AsrSetting.fromJson(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    return AsrSetting(
      encoder: map['encoder'] as String?,
      decoder: map['decoder'] as String?,
      joiner: map['joiner'] as String?,
      single: map['single'] as String?,
      tokens: map['tokens'] as String,
      modelType: map['modelType'] as String,
      name: map['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'tokens': tokens,
      'modelType': modelType,
      if (name != null) 'name': name,
    };
    switch (modelType) {
      case 'transducer':
        data['encoder'] = encoder;
        data['decoder'] = decoder;
        data['joiner'] = joiner;
      case 'paraformer':
        data['encoder'] = encoder;
        data['decoder'] = decoder;
      case 'zipformer2Ctc':
      case 'nemoCtc':
        data['single'] = single;
    }
    return data;
  }

  String toJson() => jsonEncode(toMap());

  so.OnlineModelConfig get model {
    switch (modelType) {
      case 'transducer':
        return so.OnlineModelConfig(
          numThreads: 4,
          tokens: tokens,
          transducer: so.OnlineTransducerModelConfig(
            encoder: encoder!,
            decoder: decoder!,
            joiner: joiner!,
          ),
        );
      case 'paraformer':
        return so.OnlineModelConfig(
          numThreads: 4,
          tokens: tokens,
          paraformer: so.OnlineParaformerModelConfig(
            encoder: encoder!,
            decoder: decoder!,
          ),
        );
      case 'zipformer2Ctc':
        return so.OnlineModelConfig(
          numThreads: 4,
          tokens: tokens,
          zipformer2Ctc: so.OnlineZipformer2CtcModelConfig(model: single!),
        );
      case 'nemoCtc':
        return so.OnlineModelConfig(
          numThreads: 4,
          tokens: tokens,
          nemoCtc: so.OnlineNemoCtcModelConfig(model: single!),
        );
      default:
        throw Exception('AsrSetting: unsupported modelType "$modelType"');
    }
  }

  /// Returns true if all required fields for the current [modelType] are filled.
  bool get isValid {
    if (tokens.isEmpty) return false;
    switch (modelType) {
      case 'transducer':
        return encoder != null &&
            encoder!.isNotEmpty &&
            decoder != null &&
            decoder!.isNotEmpty &&
            joiner != null &&
            joiner!.isNotEmpty;
      case 'paraformer':
        return encoder != null &&
            encoder!.isNotEmpty &&
            decoder != null &&
            decoder!.isNotEmpty;
      case 'zipformer2Ctc':
      case 'nemoCtc':
        return single != null && single!.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  String toString() => toJson();
}
