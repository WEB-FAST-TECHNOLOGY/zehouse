import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './core/app_export.dart';
import './services/currency_service.dart';
import './services/language_service.dart';
import './services/mapbox_service.dart';
import './services/supabase_service.dart';
import './widgets/custom_error_widget.dart';

import 'services/mapbox_init_web.dart'
    if (dart.library.io) 'services/mapbox_init_io.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as google_mobile_ads;
import 'services/ad_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Failed to initialize Firebase/Notifications: $e');
  }

  // Load theme mode from local settings
  try {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('theme_mode') ?? 'light';
    if (themeString == 'dark') {
      AppTheme.themeModeNotifier.value = ThemeMode.dark;
    } else if (themeString == 'system') {
      AppTheme.themeModeNotifier.value = ThemeMode.system;
    } else {
      AppTheme.themeModeNotifier.value = ThemeMode.light;
    }
  } catch (e) {
    debugPrint('Failed to load theme mode preference: $e');
  }

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize Language Service
  await LanguageService.instance.init();

  // Initialize Currency Service
  await CurrencyService.instance.init();

  // Initialize Mobile Ads SDK
  try {
    await google_mobile_ads.MobileAds.instance.initialize();
    // Pre-load interstitial and rewarded ads
    AdHelper.loadInterstitial();
    AdHelper.loadRewarded();
  } catch (e) {
    debugPrint('Failed to initialize AdMob: $e');
  }

  // Initialize Mapbox access token via MapboxService
  if (MapboxService.accessToken.isNotEmpty) {
    try {
      await initMapbox(MapboxService.accessToken);
    } catch (_) {}
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  // SystemChrome.setPreferredOrientations is a no-op on web; guard it to
  // avoid wrapping runApp in a .then() chain that could silently swallow errors.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
        Locale('ar'),
        Locale('es'),
        Locale('pt'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('fr'),
      startLocale: const Locale('fr'),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, themeMode, _) {
        return Sizer(
          builder: (context, orientation, screenType) {
            // Update the dynamic colors static flag before Material App compiles widgets
            final brightness =
                WidgetsBinding.instance.platformDispatcher.platformBrightness;
            AppTheme.isDark = themeMode == ThemeMode.system
                ? (brightness == Brightness.dark)
                : (themeMode == ThemeMode.dark);

            return MaterialApp(
              title: 'zehouse',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                );
              },
              // 🚨 END CRITICAL SECTION
              debugShowCheckedModeBanner: false,
              routes: AppRoutes.routes,
              initialRoute: AppRoutes.initial,
            );
          },
        );
      },
    );
  }
}
