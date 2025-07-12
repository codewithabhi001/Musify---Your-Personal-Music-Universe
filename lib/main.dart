import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:musify/routes/routes.dart';
import 'package:musify/controllers/player_controller.dart';

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
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Musify - Your Personal Music Universe',
      initialRoute: AppRoutes.SPLASH,
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
