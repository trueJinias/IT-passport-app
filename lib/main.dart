import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'screens/tutorial_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  bool isFirstLaunch = true;

  try {
    // Set a timeout for all initialization to prevent splash screen hang
    await Future.any([
      Future(() async {
        try {
          MobileAds.instance.initialize();
          
          final notificationService = NotificationService();
          await notificationService.init();
          await notificationService.scheduleDailyReminder();
          
          final prefs = await SharedPreferences.getInstance();
          isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
        } catch (e) {
          debugPrint('Startup inner error: $e');
        }
      }),
      Future.delayed(const Duration(seconds: 3)),
    ]);
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(
    ProviderScope(
      child: MyApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    // Remove splash after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });

    return MaterialApp(
      title: 'ITパスポート 一問一答',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData(brightness: Brightness.light).textTheme),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
      ),
      themeMode: themeMode,
      home: isFirstLaunch ? const TutorialScreen() : const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
