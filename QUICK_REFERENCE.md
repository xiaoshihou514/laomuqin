# ASR Implementation Quick Reference

## File Locations

### lib_other_project/ (Reference Implementation)
- **ASR Settings UI**: `pages/settings/asr_settings.dart` (458 lines)
- **Download/Extract**: `components/download_unzip.dart` (210 lines)
- **ASR Service**: `services/speech.dart` (50 lines)
- **Model Config**: `utils/data/asr_setting.dart` (100 lines)
- **Secure Storage**: `services/secure_storage.dart` (21 lines)

### lib/ (New Implementation)
- **ASR Service**: `data/services/asr_service.dart` (67 lines)
- **Model Config**: `data/models/asr_setting.dart` (208 lines)
- **ASR Settings UI**: `ui/settings/asr_settings_page.dart` (349 lines)
- **Recording Sheet**: `ui/main/widgets/asr_recording_sheet.dart` (233 lines)
- **Main ViewModel**: `ui/main/main_viewmodel.dart` (180 lines)
- **Settings Repository**: `data/repositories/settings_repository.dart` (71 lines)
- **Preferences Service**: `data/services/shared_preferences_service.dart` (42 lines)

---

## ASR Model Downloading (lib_other_project only)

### Packages
```dart
import 'package:dio/dio.dart';                    // HTTP download
import 'package:archive/archive_io.dart';        // Extract archives
import 'package:path_provider/path_provider.dart'; // App directories
```

### Download Flow
```
1. User selects preset in settings
2. Clicks Save
3. Check if model dir exists locally
4. If not: show DownloadUnzipDialog
5. Dio downloads to cache directory (temp)
6. archive_io extracts to support directory (final)
7. Update progress UI during each stage
```

### File Locations
- **Temp**: `getApplicationCacheDirectory()` → `/cache/model.tar.bz2`
- **Final**: `getApplicationSupportDirectory()` → `/support/model-name/`

### Progress Tracking
```dart
Dio().download(url, tmpPath, onReceiveProgress: (received, total) {
  setState(() => progress = _ntrunc(received / total));  // 0-100
});
```

### Supported Archives
tar.gz, tgz, tar.bz2, tbz, tar.xz, txz, tar, zip

---

## ASR Transcription

### Legacy (lib_other_project)
```dart
import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

String result = await Speech.fromWAV(
  modelConfig,      // OnlineModelConfig
  zdppConfig,       // Optional punctuation
  audioData,        // Float32List (PCM)
  sampleRate,       // 22050, 16000, etc.
);
```

### New (lib)
```dart
String result = await AsrService.transcribe(
  settingJson: model_json,     // AsrSetting as JSON
  samples: audioData,          // Float32List (PCM)
  sampleRate: 22050,           // Hz
);
// Runs in background isolate (non-blocking UI)
```

### Recording
```dart
const _kSampleRate = 22050;
await _recorder.init(
  channels: RecorderChannels.mono,
  format: PCMFormat.f32le,  // 32-bit float
);
// Listen to stream and collect Float32List
```

---

## Model Types & Files Required

| Type | Encoder | Decoder | Joiner | Single | Tokens |
|------|---------|---------|--------|--------|--------|
| transducer | ✓ | ✓ | ✓ | ✗ | ✓ |
| paraformer | ✓ | ✓ | ✗ | ✗ | ✓ |
| zipformer2Ctc | ✗ | ✗ | ✗ | ✓ | ✓ |
| nemoCtc | ✗ | ✗ | ✗ | ✓ | ✓ |
| toneCtc | ✗ | ✗ | ✗ | ✓ | ✓ |

### Preset Models (lib_other_project)

1. **zh_en_zipformer** (transducer)
   - URL: `.../sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20.tar.bz2`
   - Files: encoder.int8.onnx, decoder.int8.onnx, joiner.int8.onnx, tokens.txt

2. **zh_en_paraformer** (paraformer)
   - URL: `.../sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2`
   - Files: encoder.onnx, decoder.onnx, tokens.txt

3. **zh_zipformer2ctc** (zipformer2Ctc)
   - URL: `.../sherpa-onnx-streaming-zipformer-ctc-zh-xlarge-int8-2025-06-30.tar.bz2`
   - Files: model.int8.onnx, tokens.txt

4. **en_nemo** (nemoCtc)
   - URL: `.../sherpa-onnx-nemo-ctc-en-conformer-small.tar.bz2`
   - Files: model.int8.onnx, tokens.txt

Base URLs:
- Global: `https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/`
- China: `https://ghfast.top/github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/`

---

## Settings Storage

### lib_other_project (Secure Storage)
```dart
import 'package:jiyi/services/secure_storage.dart' as ss;

// Read
final json = await ss.read(key: ss.ASR_MODEL_SETTINGS);
final setting = AsrSetting.fromJson(json!);

// Write
await ss.write(key: ss.ASR_MODEL_SETTINGS, value: setting.json);

// Delete (reset)
await ss.write(key: ss.ASR_MODEL_SETTINGS, value: null);
```

Storage: **FlutterSecureStorage** (encrypted)

### lib (SharedPreferences)
```dart
// Through repository layer
final result = await settingsRepo.getAsrModelSettings();
if (result is Ok<String?>) {
  final setting = AsrSetting.fromJson(result.value!);
}

// Set
await settingsRepo.setAsrModelSettings(setting.toJson());
```

Storage: **SharedPreferences** (unencrypted)

---

## Architecture Patterns

### lib_other_project
```
Page → Service (direct calls)
                ↓
           FlutterSecureStorage
```
- Global singleton services
- No dependency injection
- Direct exception throwing

### lib (Improved)
```
Page/ViewModel → Repository → Service → SharedPreferences
     ↓
  Command pattern (Command0<T>, Command1<U, T>)
  Result wrapper (Ok<T>, Error<E>)
  Streams for reactive updates
```

---

## Key Code Snippets

### Model Config Generation
```dart
final config = AsrSetting(
  modelType: 'transducer',
  encoder: '/path/encoder.onnx',
  decoder: '/path/decoder.onnx',
  joiner: '/path/joiner.onnx',
  tokens: '/path/tokens.txt',
).model;  // Returns so.OnlineModelConfig
```

### Validation
```dart
final setting = AsrSetting.fromJson(json);
if (!setting.isValid) {
  // Missing required files
}
```

### Background Transcription
```dart
final transcript = await AsrService.transcribe(
  settingJson: widget.settingJson,
  samples: Float32List.fromList(audioBuffer),
  sampleRate: 22050,
);
```

### Settings Stream (Reactive)
```dart
final settingsRepo = SettingsRepository(service);
settingsRepo.asrStream.listen((enabled) {
  print('ASR enabled: $enabled');
});
```

---

## Comparison: What Changed

| Feature | Old | New |
|---------|-----|-----|
| Download mechanism | Dio + archive_io | None |
| Background processing | Main thread | Isolate via compute() |
| Error handling | Exceptions | Result<T> type |
| Architecture | Service layer | Repository pattern |
| Settings location | SecureStorage | SharedPreferences |
| UI framework | Custom | Material 3 |
| Punctuation support | Yes (ZDPP) | No |
| Setup flow | Minimal | Full onboarding wizard |

---

## Testing Integration

To use in your project:

1. **Copy `lib/data/models/asr_setting.dart`** to your project
2. **Copy `lib/data/services/asr_service.dart`** for background transcription
3. **Copy `lib/ui/main/widgets/asr_recording_sheet.dart`** for recording UI
4. **Add dependencies** to pubspec.yaml:
   ```yaml
   sherpa_onnx: ^0.x.x
   flutter_recorder: ^0.x.x
   permission_handler: ^11.x.x
   file_picker: ^5.x.x
   ```

5. **For download support** (from lib_other_project):
   - Copy `components/download_unzip.dart`
   - Add: `dio`, `archive`

---

## Sample Rate & Audio Format

Both implementations use:
- **Sample Rate**: 22050 Hz (22.05 kHz)
- **Format**: F32LE (32-bit float, little-endian)
- **Channels**: Mono (1 channel)
- **Duration**: Variable (no fixed limit)

Recommendation: Keep sample rate at 22050 for consistency with trained models.

---

## Error Handling

### lib_other_project
```dart
try {
  final result = await Speech.fromWAV(...);
} catch (e) {
  // Handle error
}
```

### lib (Recommended)
```dart
final result = await _repository.getAsrModelSettings();
if (result is Ok<String?>) {
  // Handle success
} else if (result is Error) {
  // Handle error: result.error
}
```

---

## Common Issues & Solutions

1. **Model files not found**
   - Check `isValid` property
   - Verify file paths in settings

2. **ASR returns empty string**
   - Settings may be null
   - Audio quality too low
   - Model loading failed

3. **UI blocks during transcription** (old impl)
   - Use background isolate (compute) instead
   - See `asr_service.dart` for example

4. **Settings not persisting**
   - Check storage permission
   - Verify SharedPreferences/SecureStorage initialized

---

