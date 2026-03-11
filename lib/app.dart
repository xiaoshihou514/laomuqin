import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

import 'data/repositories/settings_repository.dart';
import 'data/repositories/task_repository.dart';
import 'l10n/app_localizations.dart';
import 'ui/main/main_page.dart';
import 'ui/main/main_viewmodel.dart';
import 'ui/settings/settings_viewmodel.dart';
import 'ui/setup/setup_page.dart';
import 'ui/setup/setup_viewmodel.dart';

class App extends StatelessWidget {
  const App({
    super.key,
    required this.settingsRepository,
    required this.taskRepository,
    required this.setupViewModel,
    required this.mainViewModel,
    required this.settingsViewModel,
    required this.showSetup,
  });

  final SettingsRepository settingsRepository;
  final TaskRepository taskRepository;
  final SetupViewModel setupViewModel;
  final MainViewModel mainViewModel;
  final SettingsViewModel settingsViewModel;
  final bool showSetup;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: setupViewModel),
        ChangeNotifierProvider.value(value: mainViewModel),
        ChangeNotifierProvider.value(value: settingsViewModel),
      ],
      child: ListenableBuilder(
        listenable: settingsViewModel,
        builder: (_, _) => MaterialApp(
          title: '老母亲',
          theme: _buildTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: settingsViewModel.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: showSetup
              ? SetupPage(viewModel: setupViewModel)
              : const MainPage(),
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
      useMaterial3: true,
      extensions: [TDThemeData.defaultData()],
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1976D2),
      brightness: Brightness.dark,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      extensions: [TDThemeData.defaultData()],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
      ),
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
