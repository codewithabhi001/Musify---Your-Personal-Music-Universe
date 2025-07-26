import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/song_repository.dart';
import 'data/repositories/audio_repository.dart';
import 'presentation/blocs/song_bloc.dart';
import 'presentation/blocs/player_bloc.dart';
import 'presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MusifyApp(prefs: prefs));
}

class MusifyApp extends StatelessWidget {
  final SharedPreferences prefs;
  const MusifyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SongRepository>(create: (_) => SongRepository()),
        RepositoryProvider<AudioRepository>(
            create: (_) => AudioRepositoryImpl(prefs)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SongBloc>(
            create: (context) =>
                SongBloc(context.read<SongRepository>())..add(LoadSongs()),
          ),
          BlocProvider<PlayerBloc>(
            create: (context) => PlayerBloc(context.read<AudioRepository>()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Musify',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: PermissionGate(),
        ),
      ),
    );
  }
}

class PermissionGate extends StatefulWidget {
  const PermissionGate({super.key});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool? _hasPermission;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      // Check Android version and request appropriate permissions
      if (await _isAndroid13OrHigher()) {
        // Android 13+ uses granular media permissions
        List<Permission> permissionsToRequest = [];
        
        // Check audio permission
        final audioStatus = await Permission.audio.status;
        if (!audioStatus.isGranted) {
          permissionsToRequest.add(Permission.audio);
        }
        
        // Check notification permission (optional but recommended)
        final notificationStatus = await Permission.notification.status;
        if (!notificationStatus.isGranted) {
          permissionsToRequest.add(Permission.notification);
        }
        
        if (permissionsToRequest.isNotEmpty) {
          final results = await permissionsToRequest.request();
          // Check if audio permission is granted (notification is optional)
          final audioGranted = results[Permission.audio]?.isGranted ?? audioStatus.isGranted;
          setState(() => _hasPermission = audioGranted);
        } else {
          setState(() => _hasPermission = true);
        }
      } else {
        // Android 12 and below - use storage permission
        final status = await Permission.storage.status;
        if (status.isGranted) {
          setState(() => _hasPermission = true);
        } else {
          final result = await Permission.storage.request();
          setState(() => _hasPermission = result.isGranted);
        }
      }
    } catch (e) {
      print('Permission error: $e');
      // Fallback to storage permission
      try {
        final status = await Permission.storage.status;
        if (status.isGranted) {
          setState(() => _hasPermission = true);
        } else {
          final result = await Permission.storage.request();
          setState(() => _hasPermission = result.isGranted);
        }
      } catch (fallbackError) {
        print('Fallback permission error: $fallbackError');
        setState(() => _hasPermission = false);
      }
    }
  }
  
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt >= 33; // Android 13 is API level 33
    } catch (e) {
      print('Error checking Android version: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermission == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasPermission!) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Permission Required',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Musify needs storage permission to load your songs. Please grant permission to continue.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _checkAndRequestPermission,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Grant Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Permission granted: show the app
    return const SplashPage(); // or HomePage if you want to skip splash
  }
}
