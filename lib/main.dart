import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:book_club_app/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'presentation/providers/error_provider.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/routes/app_router.dart';
import 'presentation/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: BookClubApp()));
}

class BookClubApp extends ConsumerWidget {
  const BookClubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Alquimia Literaria',
      // Task 13.2: consistent design system with Alquimia Literaria branding
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode, // Controlled by theme provider
      locale: locale, // Controlled by locale provider (null = system language)
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      // Task 13.3: global network error listener wraps the entire app shell
      builder: (context, child) => NetworkErrorListener(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
