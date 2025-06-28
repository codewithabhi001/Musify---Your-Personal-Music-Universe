import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:musify/routes/routes.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register PlayerController (AudioService is initialized inside PlayerController)
  Get.put(PlayerController());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Request permissions after the widget is initialized
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (status.isDenied) {
          Get.snackbar(
            'Permission Denied',
            'Please enable notifications in system settings for media controls.',
            snackPosition: SnackPosition.BOTTOM,
          );
          await openAppSettings();
        }
      } else if (Platform.isIOS) {
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('Permission request error: $e');
      Get.snackbar(
        'Error',
        'Failed to request notification permission: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Music App',
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
        scheme: FlexScheme.bahamaBlue,
        useMaterial3: true,
        appBarElevation: 2,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 15,
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
