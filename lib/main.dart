import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:musify/routes/routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
