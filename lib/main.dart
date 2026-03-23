import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/main_screen.dart';
import 'screens/tutorial_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

class MyApp extends ConsumerStatefulWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Remove splash after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FlutterNativeSplash.remove();
      if (!kIsWeb && Platform.isAndroid && !widget.isFirstLaunch) {
        final granted = await NotificationService().requestPermission();
        if (!granted && mounted) {
          _showNotificationDisabledDialog(context);
        }
      }
    });
    _rescheduleNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rescheduleNotifications();
    }
  }

  void _showNotificationDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('通知が無効です'),
        content: const Text(
          '学習リマインダーを受け取るには、通知を許可してください。\n\n'
          '設定 → アプリ → ITパスポート 過去問精釈 → 通知 → 許可',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 通知を再スケジュール（端末再起動後の復元など）
  Future<void> _rescheduleNotifications() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final notificationService = NotificationService();
        await notificationService.scheduleDailyReminder();
      } catch (e) {
        debugPrint('Failed to reschedule notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'ITパスポート 過去問精釈',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData(brightness: Brightness.light).textTheme),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansJpTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        ),
      ),
      themeMode: themeMode,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          ),
          child: child!,
        );
      },
      home: widget.isFirstLaunch ? const TutorialScreen() : const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
