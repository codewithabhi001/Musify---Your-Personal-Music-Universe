import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/routes/routes.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:musify/service/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request permissions
  await requestPermissions();

  // Initialize Awesome Notifications
  await AwesomeNotifications().initialize(
    null, // Default icon
    [
      NotificationChannel(
        channelKey: 'musify_playback',
        channelName: 'Musify Playback',
        channelDescription: 'Media playback controls for Musify',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: false,
        enableVibration: false,
        channelShowBadge: false,
        locked: true,
      ),
    ],
    debug: true,
  );

  // Set notification listeners
  await NotificationService.startListeningNotificationEvents();

  // Initialize GetX controllers in correct order
  Get.put(SongController());
  Get.put(FavoriteController());
  final player = AudioPlayer();
  Get.put(NotificationService(player)); // Initialize NotificationService first
  Get.put(PlayerController()); // Then PlayerController

  runApp(const MyApp());
}

Future<void> requestPermissions() async {
  await [
    Permission.storage,
    Permission.audio,
    Permission.manageExternalStorage,
    Permission.notification,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musify',
      navigatorKey: navigatorKey,
      initialRoute: AppRoutes.HOME,
      getPages: AppRoutes.routes,
      theme: FlexThemeData.light(
        scheme: FlexScheme.deepBlue,
        useMaterial3: true,
        appBarElevation: 2,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 9,
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          inputDecoratorRadius: 12,
          chipRadius: 12,
          dialogRadius: 16,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      darkTheme: FlexThemeData.dark(
        scheme: FlexScheme.flutterDash,
        useMaterial3: true,
        appBarElevation: 2,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 40,
        subThemesData: const FlexSubThemesData(
          interactionEffects: true,
          tintedDisabledControls: true,
          inputDecoratorRadius: 12,
          chipRadius: 12,
          dialogRadius: 16,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
