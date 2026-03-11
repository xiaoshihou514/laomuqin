# Architecture & Flow Diagrams

## ASR Model Download Flow (lib_other_project)

```
┌─────────────────────────────────────────────────────────────┐
│                    User Action                              │
│  1. Navigate to ASR Settings                               │
│  2. Select Preset Model                                    │
│  3. Click Save                                             │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
            ┌──────────────────────┐
            │  Check Model Exists  │
            │ in support directory │
            └──────┬─────────┬──────┘
                   │         │
         Yes (skip)│         │No (download)
                   │         │
                   ▼         ▼
            ┌──────────┐  ┌─────────────────────────┐
            │   Done   │  │  Show DownloadUnzipDialog
            └──────────┘  └────────┬────────────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
              Stage: Downloading            onReceiveProgress
              ┌─────────────────┐           Callback fires:
              │                 │           - received (int)
              │  Dio.download() │────┐      - total (int)
              │  to cache dir   │    │      - progress = received/total
              │  /cache/model   │    │      - UI updates LinearProgressIndicator
              └─────────────────┘    │
                                     ▼
                           ┌──────────────────────┐
                           │ Progress = Downloading
                           │ [████░░░░░░░░░░░] 35%
                           └──────────────────────┘
                                     │
                                     ▼
              ┌─────────────────────────────────────┐
              │    Extract Archive to Support Dir    │
              │  Stage: Unzipping                   │
              │  extractFileToDisk(cache, support)  │
              │  [████████████████████████████] 100%│
              └──────────────┬──────────────────────┘
                             │
                             ▼
              ┌─────────────────────────────────────┐
              │    Stage: Done                      │
              │    Save Settings                    │
              │  [████████████████████████████] 100%│
              │    Download Complete ✓              │
              └─────────────────────────────────────┘
```

### File Path Transformation
```
Download URL:
  https://github.com/.../asr-models/sherpa-onnx-streaming-zipformer-zh-en.tar.bz2

↓

Temp Location (downloading):
  /data/data/app/cache/sherpa-onnx-streaming-zipformer-zh-en.tar.bz2

↓

Extract to:
  /data/data/app/support/sherpa-onnx-streaming-zipformer-zh-en/
  ├── encoder-epoch-99-avg-1.int8.onnx
  ├── decoder-epoch-99-avg-1.int8.onnx
  ├── joiner-epoch-99-avg-1.int8.onnx
  └── tokens.txt

↓

Paths stored in settings (SecureStorage):
  {
    "encoder": "/data/data/app/support/sherpa-onnx-streaming-zipformer-zh-en/encoder-epoch-99-avg-1.int8.onnx",
    "decoder": "/data/data/app/support/sherpa-onnx-streaming-zipformer-zh-en/decoder-epoch-99-avg-1.int8.onnx",
    "joiner": "/data/data/app/support/sherpa-onnx-streaming-zipformer-zh-en/joiner-epoch-99-avg-1.int8.onnx",
    "tokens": "/data/data/app/support/sherpa-onnx-streaming-zipformer-zh-en/tokens.txt",
    "modelType": "transducer",
    "name": "zh_en_streaming_zipformer"
  }
```

---

## ASR Transcription Flow

### lib_other_project (Main Thread)
```
┌─────────────────────────────────────┐
│  User clicks Mic in RecordingPage   │
└──────────────┬──────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│  AudioRecorder initialization        │
│  - Mono, F32LE format               │
│  - StartStreamingData()             │
│  - Listen to uint8List stream       │
└──────────────┬──────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│  Recording (30 seconds)              │
│  - Collect audio chunks             │
│  - Convert to Float32List           │
│  - Accumulate in _bytes buffer      │
└──────────────┬──────────────────────┘
               │
               ▼
┌──────────────────────────────────────┐
│  User clicks Stop                    │
│  _done() called                      │
└──────────────┬──────────────────────┘
               │
               ▼
┌────────────────────────────────────────────────────────────┐
│  Speech.fromWAV(modelConfig, data, sampleRate)            │
│  ⚠️ RUNS ON MAIN THREAD (blocks UI!)                      │
│                                                             │
│  1. so.initBindings()                                      │
│  2. OnlineRecognizer(config)  ← Load models               │
│  3. stream = recognizer.createStream()                    │
│  4. stream.acceptWaveform(samples, rate)                  │
│  5. while (isReady) recognizer.decode(stream)             │
│  6. result = recognizer.getResult(stream)                 │
│  7. recognizer.free() / stream.free()                     │
│  8. optional: zdpp(text) ← Punctuation                    │
└────────────────┬─────────────────────────────────────────┘
                 │
                 ▼
        ┌────────────────┐
        │ Return Text    │
        │ to RecordPage  │
        │ showSnackBar() │
        └────────────────┘
```

### lib (Background Isolate - Recommended)
```
┌─────────────────────────────────────┐
│  User clicks Mic & Records Audio    │
│  Same as above (main thread)        │
└──────────────┬──────────────────────┘
               │
               ▼
┌───────────────────────────────────────┐
│  _done() called                       │
│  _cancelled = true                    │
│  samples = Float32List.fromList(_bytes)
└──────────────┬────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Main Thread (UI stays responsive)       │
│                                          │
│  transcript = await AsrService.transcribe(
│    settingJson: json,
│    samples: samples,
│    sampleRate: 22050,
│  )
│                                          │
│  Returns Future<String>                  │
└──────────────┬────────────────────────┤
               │ compute() spawns       │
               └────────┬───────────────┘
                        │
         ┌──────────────┴───────────────┐
         │                              │
    Isolate 1                      Isolate 2 (Background)
    (Main UI)                    (Transcription)
         │                              │
         │                              ▼
         │                      ┌─────────────────────┐
         │                      │ _isolateEntry()     │
         │                      │                     │
         │                      │ 1. Init bindings    │
         │                      │ 2. Create recognizer
         │ (non-blocking)       │ 3. Decode stream    │
         │                      │ 4. Return text      │
         │                      │ 5. Cleanup          │
         │                      └────────┬────────────┘
         │                               │
         ├───────────────────────────────┤
         │ Future resolves with result
         │
         ▼
    ┌─────────────────┐
    │ Navigate back   │
    │ Insert to input │
    │ bar or show it  │
    └─────────────────┘
```

---

## Data Flow: Settings & ASR Configuration

### lib_other_project (Simple)
```
┌────────────────────────────┐
│   ASRSettings Page         │
│  (StatefulWidget)          │
└────────┬───────────────────┘
         │
         ▼
    (direct calls)
         │
    ┌────┴────────────────────────────────┐
    │                                     │
    ▼                                     ▼
┌──────────────────────┐      ┌──────────────────────┐
│ ss.read(key)         │      │ ss.write(key, value) │
│ ss.write(key, value) │      │ ss.delete(key)       │
└──────────┬───────────┘      └──────────┬───────────┘
           │                             │
           └──────────────┬──────────────┘
                          │
                          ▼
        ┌─────────────────────────────────┐
        │ FlutterSecureStorage            │
        │ (Encrypted)                     │
        │                                 │
        │ Key: JIYI_ASR_SETTINGS          │
        │ Value: JSON string of AsrSetting
        └─────────────────────────────────┘
```

### lib (Layered - Recommended)
```
┌────────────────────┐         ┌───────────────────────┐
│ SettingsPage       │         │ AsrSettingsPage       │
│ (UI)               │         │ (UI)                  │
└────────┬───────────┘         └───────────┬───────────┘
         │                                 │
         └───────────────────┬─────────────┘
                             │
                 ┌───────────┴───────────┐
                 │ SettingsViewModel    │
                 │ (Business Logic)     │
                 └───────────┬───────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    toggleAsr()          saveAsr...()      load()
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
              ▼ (Result<T> wrapper)        ▼
    ┌─────────────────────────┐   ┌──────────────────────┐
    │ SettingsRepository      │   │ isAsrEnabled()       │
    │ - Error handling        │   │ setAsrEnabled(bool)  │
    │ - Stream support        │   │ getAsrSettings()     │
    │ - Business logic        │   │ setAsrSettings(json) │
    └────────┬────────────────┘   └──────────┬───────────┘
             │                               │
             └─────────────────┬─────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            │                                     │
            ▼ (Low-level interface)              ▼
┌──────────────────────────────┐   ┌──────────────────────┐
│ SharedPreferencesService     │   │ isAsrEnabled()       │
│ (Storage adapter)            │   │ setAsrEnabled(bool)  │
│                              │   │ getAsrModelSettings()│
│ Constants:                   │   │ setAsrModelSettings()
│ - _kAsrEnabled = 'asrEnabled'        │
│ - _kAsrModelSettings = ...   │   └──────────┬───────────┘
└──────────┬───────────────────┘             │
           │                                 │
           └─────────────────┬───────────────┘
                             │
                             ▼
              ┌──────────────────────────┐
              │ SharedPreferences        │
              │ (Unencrypted storage)    │
              │                          │
              │ Key: asrEnabled          │
              │ Value: bool              │
              │                          │
              │ Key: asrModelSettings    │
              │ Value: JSON string       │
              └──────────────────────────┘
```

---

## ASR Model Type System

```
┌───────────────────────────────────────────────────────────┐
│              ASR Model Types (5 supported)                │
└───────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ TRANSDUCER (Encoder + Decoder + Joiner)                 │
│ ✓ Streaming support                                      │
│ ✓ Real-time transcription                               │
│ ✓ Bilingual (zh + en)                                   │
│                                                          │
│ Files:                                                   │
│   encoder.int8.onnx        ← Acoustic features           │
│   decoder.int8.onnx        ← Predicts tokens            │
│   joiner.int8.onnx         ← Combines encoder+decoder   │
│   tokens.txt               ← Vocabulary mapping          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ PARAFORMER (Encoder + Decoder)                           │
│ ✓ Non-autoregressive (faster)                           │
│ ✓ Streaming capable                                      │
│ ✓ Bilingual (zh + en)                                   │
│                                                          │
│ Files:                                                   │
│   encoder.onnx             ← Acoustic features           │
│   decoder.onnx             ← Non-AR decoder             │
│   tokens.txt               ← Vocabulary mapping          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ ZIPFORMER2CTC (Single Model)                             │
│ ✓ Simpler architecture                                   │
│ ✓ CTC loss (Connectionist Temporal Classification)       │
│ ✓ Chinese language specialized                           │
│                                                          │
│ Files:                                                   │
│   model.int8.onnx          ← Full ASR model             │
│   tokens.txt               ← Vocabulary mapping          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ NEMOCTC (Single Model)                                   │
│ ✓ NVIDIA NeMo framework                                  │
│ ✓ CTC-based                                              │
│ ✓ English language specialized                           │
│                                                          │
│ Files:                                                   │
│   model.int8.onnx          ← Full ASR model             │
│   tokens.txt               ← Vocabulary mapping          │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│ TONECTC (Single Model)                                   │
│ ✓ Tone-aware (for tonal languages)                       │
│ ✓ Chinese tone recognition                              │
│ ✓ CTC-based                                              │
│                                                          │
│ Files:                                                   │
│   model.int8.onnx          ← Full ASR model             │
│   tokens.txt               ← Vocabulary mapping          │
└─────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ File Requirement Matrix                                    │
├─────────────┬──────────┬──────────┬────────┬────────────┤
│ Model Type  │ Encoder  │ Decoder  │ Joiner │ Single    │
├─────────────┼──────────┼──────────┼────────┼────────────┤
│ transducer  │    ✓     │    ✓     │   ✓    │    ✗      │
│ paraformer  │    ✓     │    ✓     │   ✗    │    ✗      │
│ zipformer2  │    ✗     │    ✗     │   ✗    │    ✓      │
│ nemoctc     │    ✗     │    ✗     │   ✗    │    ✓      │
│ tonectc     │    ✗     │    ✗     │   ✗    │    ✓      │
└─────────────┴──────────┴──────────┴────────┴────────────┘

All types require: tokens.txt (vocabulary)
```

---

## Setup Flow (lib)

```
┌─────────────────────────┐
│  App Cold Start         │
│  main() → MyApp()       │
└────────┬────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  Check: isOnboardingDone()?        │
│  (SharedPreferences)               │
└────────┬─────────────┬─────────────┘
         │ No          │ Yes
         │             │
         ▼             ▼
  SetupPage       MainPage
         │
         ▼
┌──────────────────────────────────────┐
│  SetupPage (PageView with 4 steps)   │
└──────────────────────────────────────┘
         │
         ├─ Step 0: Welcome
         │  ├─ Icon
         │  ├─ Title
         │  └─ "Next" button
         │         │
         │         ▼
         │
         ├─ Step 1: Notification Permission
         │  ├─ "Grant" (requestNotification())
         │  └─ "Skip"
         │         │
         │         ▼
         │
         ├─ Step 2: Background Permission
         │  ├─ "Grant" (requestIgnoreBatteryOptimizations())
         │  └─ "Skip"
         │         │
         │         ▼
         │
         └─ Step 3: ASR Enable/Disable
            ├─ "Enable ASR" (asrEnabled = true)
            │  └─ Save preference
            │     └─ Navigate to AsrSettingsPage
            │        (User configures ASR models here)
            │        └─ Then MainPage
            │
            └─ "Skip ASR" (asrEnabled = false)
               └─ Save preference
                  └─ MainPage directly
```

---

## Recording Sheet Flow

```
┌──────────────────────────────────────┐
│ User opens AsrRecordingSheet         │
│ initState() → _startRecording()      │
└────────────┬─────────────────────────┘
             │
             ▼
   ┌─────────────────────────┐
   │ Request microphone perm │
   │ Permission.microphone   │
   └────────┬────────────────┘
            │
            ▼
   ┌──────────────────────────────┐
   │ Recorder.init(               │
   │   channels: mono,            │
   │   format: PCMFormat.f32le     │
   │ )                            │
   └────────┬─────────────────────┘
            │
            ▼
   ┌──────────────────────────────┐
   │ recorder.start()             │
   │ recorder.startStreamingData()│
   │ startTimer()                 │
   │ _recording = true            │
   └────────┬─────────────────────┘
            │
        ┌───┴────────────────────────┐
        │                            │
        ▼ (Loop: collect data)       ▼ (UI Updates)
   ┌─────────────────┐          ┌─────────────────┐
   │ Listen to       │          │ Timer updates:  │
   │ uint8ListStream │          │ MM:SS (00:15)   │
   │                 │          │                 │
   │ data.toF32List()│          │ Icon changes:   │
   │ _bytes.addAll() │          │ ✓ Idle → Red    │
   └────────┬────────┘          └────────┬────────┘
            │                           │
            └───────────┬───────────────┘
                        │
    ┌───────────────────┴─────────────────────┐
    │  User clicks STOP button                │
    │  _done() called                         │
    └───────────────┬───────────────────────────┘
                    │
                    ▼
    ┌──────────────────────────────────────┐
    │ Cancel recording                     │
    │ recorder.stopStreamingData()          │
    │ recorder.deinit()                    │
    │ timer.cancel()                       │
    │ _processing = true (show spinner)    │
    └──────────────┬───────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │ Float32List samples =               │
    │   Float32List.fromList(_bytes)      │
    │                                     │
    │ transcript = AsrService.transcribe( │
    │   settingJson: widget.settingJson,  │
    │   samples: samples,                 │
    │   sampleRate: 22050                 │
    │ )                                   │
    │ (Background isolate processing)     │
    └──────────────┬───────────────────────┘
                   │
        ┌──────────┴──────────┐
        │ Transcription done  │
        │ (10-30 seconds)     │
        └──────────┬──────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │ Navigator.pop(context, transcript)  │
    │ Caller receives text and inserts    │
    │ into input field                    │
    └─────────────────────────────────────┘
```

---

## Command Pattern Execution Flow

```
┌──────────────────────────────────────┐
│  SettingsViewModel initialization    │
└──────────────┬───────────────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │ load = Command0(_load)   │
    │   ..execute()            │ ← Auto-executed
    │                          │
    │ toggleAsr =              │
    │   Command0(_toggleAsr)   │
    │                          │
    │ saveAsrModelSettings =   │
    │   Command1<String?, void>│
    │     (_saveAsrModelSettings)
    └──────────────────────────┘
               │
    ┌──────────┴──────────┬─────────────┐
    │                     │             │
    ▼                     ▼             ▼
 _load()          _toggleAsr()  _saveAsrModelSettings()
    │                     │             │
    │                     ▼             ▼
    │             -asrEnabled =    settingsRepo
    │              !asrEnabled    .setAsrModelSettings(json)
    │                     │             │
    │                     ▼             ▼
    ▼                 Result<void>  Result<void>
Result<void>                │             │
    │                       │             │
    ├─ Ok(value)       ┌────┴──────┐ ┌───┴────┐
    │  _asrEnabled = ? │           │ │        │
    │  _asrModelSettingsJson = ?   │ │        │
    │  notifyListeners()           │ │        │
    │                  │           │ │        │
    └─ Error(e)       │        Ok ├─┴─ Ok   │
       catch & return  │        │        │
                       │        │        │
                       │        ▼        ▼
                       │    Update UI   SnackBar
                       │    notifyListeners()
                       │    setState()
                       │
                    Error(e)
                       │
                       ▼
                    SnackBar Error

UI calls:
viewModel.toggleAsr.execute()
    │
    returns: Future<Result<void>>
    │
    then((_) { ... }) or await


```

---

## Preset Model Download URLs

```
Base URLs:
├─ Global: https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/
└─ China:  https://ghfast.top/github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/

Available Models:
│
├─ sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20.tar.bz2
│  ├─ Type: transducer
│  ├─ Languages: Chinese + English
│  ├─ Size: ~250MB (compressed)
│  └─ Files inside:
│     ├─ encoder-epoch-99-avg-1.int8.onnx
│     ├─ decoder-epoch-99-avg-1.int8.onnx
│     ├─ joiner-epoch-99-avg-1.int8.onnx
│     └─ tokens.txt
│
├─ sherpa-onnx-streaming-paraformer-bilingual-zh-en.tar.bz2
│  ├─ Type: paraformer (non-autoregressive)
│  ├─ Languages: Chinese + English
│  ├─ Speed: Faster than transducer
│  └─ Files inside:
│     ├─ encoder.onnx
│     ├─ decoder.onnx
│     └─ tokens.txt
│
├─ sherpa-onnx-streaming-zipformer-ctc-zh-xlarge-int8-2025-06-30.tar.bz2
│  ├─ Type: zipformer2Ctc
│  ├─ Language: Chinese only
│  ├─ Specialized for Mandarin
│  └─ Files inside:
│     ├─ model.int8.onnx
│     └─ tokens.txt
│
└─ sherpa-onnx-nemo-ctc-en-conformer-small.tar.bz2
   ├─ Type: nemoCtc
   ├─ Language: English only
   ├─ Framework: NVIDIA NeMo
   └─ Files inside:
      ├─ model.int8.onnx
      └─ tokens.txt
```

---

