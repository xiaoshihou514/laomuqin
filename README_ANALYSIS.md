# Laomuqin Project - Complete ASR Analysis

This directory contains comprehensive documentation of the ASR (Automatic Speech Recognition) implementation in both the `lib_other_project/` (reference/legacy) and `lib/` (new) directories.

## 📋 Documentation Files

### 1. **DETAILED_ANALYSIS.txt** (1188 lines)
**Comprehensive breakdown of both implementations**
- Complete file listings for both directories (59 files in lib_other_project, 25 in lib)
- Detailed walkthrough of ASR model downloading (Dio + archive_io)
- ASR initialization & transcription workflows
- Service patterns (legacy vs improved architecture)
- ASR settings configuration
- Complete code examples and flows

**Best for:** Understanding the full picture, learning implementation details

### 2. **QUICK_REFERENCE.md**
**Quick lookup guide for developers**
- File locations with line counts
- Code snippets for common tasks
- Model types & file requirements table
- Download URLs for preset models
- Settings storage patterns
- Architecture patterns comparison
- Common issues & solutions

**Best for:** Quick lookups, implementing features, troubleshooting

### 3. **ARCHITECTURE_DIAGRAMS.md**
**Visual ASCII diagrams of all major flows**
- ASR model download flow with state transitions
- File path transformations
- Transcription flows (main thread vs isolate)
- Data flow diagrams (simple vs layered)
- Model type system breakdown
- Setup wizard flow
- Recording sheet state machine
- Command pattern execution
- Preset model URLs organized

**Best for:** Visual learners, understanding system interactions, documentation

---

## 🎯 Quick Navigation

### "I want to understand..."

- **ASR Model Downloading** → See DETAILED_ANALYSIS.txt §1 + ARCHITECTURE_DIAGRAMS.md (Download Flow)
- **How Transcription Works** → DETAILED_ANALYSIS.txt §2 + ARCHITECTURE_DIAGRAMS.md (Transcription Flows)
- **Setting/Configuration Management** → DETAILED_ANALYSIS.txt §3 + ARCHITECTURE_DIAGRAMS.md (Data Flow Diagram)
- **Implementing in My Project** → QUICK_REFERENCE.md (Testing Integration section)
- **File Paths & Formats** → ARCHITECTURE_DIAGRAMS.md (File Path Transformation + Preset Model URLs)
- **Model Types** → QUICK_REFERENCE.md (Model Types table) + ARCHITECTURE_DIAGRAMS.md (Model Type System)

### "I want to implement..."

- **Download with Progress UI** → Copy `lib_other_project/components/download_unzip.dart`
- **Background ASR Processing** → Copy `lib/data/services/asr_service.dart`
- **ASR Settings UI** → Copy `lib/ui/settings/asr_settings_page.dart`
- **Recording Interface** → Copy `lib/ui/main/widgets/asr_recording_sheet.dart`
- **Repository Pattern** → Copy `lib/data/repositories/settings_repository.dart`

---

## 📊 Key Findings Summary

### lib_other_project (Reference Implementation)
✅ **Features:**
- Auto-download of ASR models using Dio
- Real-time download progress tracking
- Automatic archive extraction
- Offline punctuation support (ZDPP)
- 5 model types supported
- Secure encrypted storage
- 4 preset models (zh+en, zh, en)

⚠️ **Limitations:**
- Main thread transcription (UI blocking)
- Direct service calls (no DI)
- Exception-based error handling
- No repository layer

### lib (New Implementation - Improved)
✅ **Improvements:**
- Background isolate processing (non-blocking)
- Layered architecture (repository pattern)
- Result<T> error handling (no exceptions)
- Command pattern for consistent async ops
- Dependency injection ready
- Full onboarding wizard
- Material Design 3 UI

⚠️ **Limitations:**
- No auto-download (manual file selection only)
- No ZDPP punctuation support
- 4 model types (no toneCtc)
- Unencrypted SharedPreferences storage

---

## �� Architecture Comparison

```
lib_other_project          lib (Recommended)
─────────────────────      ────────────────────────
UI Page                    UI Page
  ↓                          ↓
Service (direct call)      ViewModel
  ↓                          ↓
SecureStorage            Repository (Result<T>)
                             ↓
                          Service
                             ↓
                       SharedPreferences
```

---

## 📱 ASR Recording Flow (Simplified)

```
1. User clicks mic
2. Permission request (microphone)
3. Initialize recorder (mono, F32LE, 22050 Hz)
4. Stream audio data → Float32List buffer
5. User clicks stop
6. Send to AsrService.transcribe() [background isolate]
7. Wait for result
8. Insert transcript to input field
9. Close recording sheet
```

**Key:** Audio format is **32-bit float, little-endian, 22050 Hz, mono**

---

## 🧠 Model System

All ASR models use **tokens.txt** + model-specific files:

| Model Type | Structure | Languages | Speed |
|-----------|-----------|-----------|-------|
| transducer | 3 files (encoder+decoder+joiner) | zh+en | Medium |
| paraformer | 2 files (encoder+decoder) | zh+en | Fast |
| zipformer2Ctc | 1 file | zh | High precision |
| nemoCtc | 1 file | en | High precision |
| toneCtc | 1 file | zh (tones) | High precision |

---

## 📥 Storage Locations

**Temporary (downloading):**
```
/data/data/app/cache/model.tar.bz2
```

**Final (after extraction):**
```
/data/data/app/support/model-name/
├── encoder.onnx
├── decoder.onnx
├── joiner.onnx (if applicable)
└── tokens.txt
```

**Settings:**
- **lib_other_project:** FlutterSecureStorage (encrypted)
- **lib:** SharedPreferences (unencrypted)

---

## 🔗 Dependencies

### Core ASR
- `sherpa_onnx` - ONNX model runtime & ASR backend
- `flutter_recorder` - Audio recording

### UI & Permissions
- `permission_handler` - Request permissions
- `file_picker` - Select model files
- `tdesign_flutter` - UI components (lib only)

### Storage (Download/Settings)
- `dio` - HTTP downloading (lib_other_project)
- `archive` - Archive extraction (lib_other_project)
- `flutter_secure_storage` - Encrypted storage (lib_other_project)
- `shared_preferences` - Settings storage (lib)

### Utilities
- `path_provider` - App directories
- `path` - Path manipulation
- `url_launcher` - Open links (lib_other_project)

---

## 💡 Best Practices

1. **Always validate ASR settings** before transcribing
   ```dart
   if (!setting.isValid) return '';
   ```

2. **Use background isolate** for transcription (non-blocking UI)
   ```dart
   await AsrService.transcribe(...) // Uses compute()
   ```

3. **Use repository pattern** for settings (DI-friendly, testable)
   ```dart
   final result = await settingsRepo.getAsrModelSettings();
   if (result is Ok<String?>) { ... }
   ```

4. **Validate file paths** after user selection
   ```dart
   final setting = AsrSetting.fromJson(json);
   if (!File(setting.encoder!).existsSync()) { ... }
   ```

5. **Show progress during download** (if implementing)
   ```dart
   onReceiveProgress: (received, total) {
     setState(() => progress = (received / total) * 100);
   }
   ```

---

## 🐛 Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| "Model files not found" | Invalid paths | Check `isValid` property |
| ASR returns empty string | Null settings or low audio quality | Validate settings exist, check audio |
| UI freezes during transcription | Main thread processing | Use background isolate (`compute()`) |
| Settings not saving | Storage not initialized | Wait for `SharedPreferences.getInstance()` |
| Download fails | Network or invalid URL | Check URL format, verify connectivity |
| Transcription times out | Model too large or device slow | Use smaller model, reduce audio length |

---

## 📞 File Cross-References

### When modifying ASR model config:
- Update `data/models/asr_setting.dart`
- Update `ui/settings/asr_settings_page.dart` preset list
- Update validation logic in `isValid` getter

### When adding new model type:
- Add to `kAsrModelTypes` list
- Add case to `model` getter (OnlineModelConfig)
- Add case to `toMap()` serialization
- Add case to `isValid` validation
- Add `AsrPreset` if providing default

### When changing download flow:
- Modify `components/download_unzip.dart`
- Update progress tracking code
- Update file extraction logic
- Update final path generation

---

## 📝 Notes

- Sample rate is hardcoded to **22050 Hz** in both implementations
- Audio format is always **F32LE mono** (32-bit float, little-endian, single channel)
- Maximum model size: Limited by device RAM (typical ~500MB)
- Transcription speed: 5-30 seconds depending on audio length and device
- China CDN (ghfast.top) is faster for mainland users

---

## 🎓 Learning Resources

1. **Understanding Sherpa-ONNX:** See speech.dart & asr_service.dart for stream processing
2. **Download & Extract:** See download_unzip.dart for progress UI pattern
3. **Repository Pattern:** See settings_repository.dart for layered architecture
4. **Command Pattern:** See utils/command.dart for async operation consistency
5. **Dart Isolates:** See _isolateEntry() in asr_service.dart for background processing

---

## 📄 Document Versions

- **Analysis Date:** March 2025
- **Scope:** Complete ASR implementations across both project directories
- **Coverage:** File-level breakdown, architecture analysis, code patterns, diagrams
- **Accuracy:** Based on direct code inspection of all relevant files

---

**For detailed implementation examples, see the source files directly:**
- `lib_other_project/components/download_unzip.dart` (210 lines)
- `lib/ui/main/widgets/asr_recording_sheet.dart` (233 lines)
- `lib/data/services/asr_service.dart` (67 lines)
- `lib/data/models/asr_setting.dart` (208 lines)

