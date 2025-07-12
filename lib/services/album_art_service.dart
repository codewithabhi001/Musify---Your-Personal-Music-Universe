import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audiotags/audiotags.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter/foundation.dart';

Future<Uint8List?> _blurImageIsolate(Map<String, dynamic> args) async {
  final Uint8List art = args['art'];
  final int blur = args['blur'];
  try {
    final img.Image? image = img.decodeImage(art);
    if (image == null) return null;
    // Downscale for performance
    final img.Image resized = img.copyResize(image, width: 64, height: 64);
    final img.Image blurred = img.gaussianBlur(resized, radius: blur);
    return Uint8List.fromList(img.encodeJpg(blurred, quality: 50));
  } catch (e) {
    debugPrint('Error in isolate blur: $e');
    return null;
  }
}

class AlbumArtService {
  static final AlbumArtService _instance = AlbumArtService._internal();
  factory AlbumArtService() => _instance;
  AlbumArtService._internal();

  final Map<String, Uint8List?> _albumArtCache = {};
  final Map<String, Color> _dominantColorCache = {};

  Future<Uint8List?> getAlbumArt(String path) async {
    if (_albumArtCache.containsKey(path)) {
      return _albumArtCache[path];
    }
    try {
      final tag = await AudioTags.read(path);
      if (tag?.pictures.isNotEmpty == true) {
        _albumArtCache[path] = tag!.pictures.first.bytes;
        return tag.pictures.first.bytes;
      }
    } catch (e) {
      debugPrint('Error loading album art for $path: $e');
    }
    _albumArtCache[path] = null;
    return null;
  }

  Future<Color> getDominantColor(String path) async {
    if (_dominantColorCache.containsKey(path)) {
      return _dominantColorCache[path]!;
    }
    final art = await getAlbumArt(path);
    if (art != null) {
      final color = await _calculateDominantColor(art);
      _dominantColorCache[path] = color;
      return color;
    }
    _dominantColorCache[path] = Colors.grey.shade800;
    return Colors.grey.shade800;
  }

  Future<Uint8List?> getBlurredAlbumArt(String path, {int blur = 32}) async {
    final art = await getAlbumArt(path);
    if (art == null) return null;
    try {
      return await compute(_blurImageIsolate, {'art': art, 'blur': blur});
    } catch (e) {
      debugPrint('Error blurring album art: $e');
      return null;
    }
  }

  Future<Color> _calculateDominantColor(Uint8List imageBytes) async {
    try {
      final img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return Colors.grey.shade800;
      Color? mostVibrant;
      double maxSaturation = 0.0;
      for (int y = 0; y < image.height; y += 2) {
        for (int x = 0; x < image.width; x += 2) {
          final pixel = image.getPixel(x, y) as int;
          final r = (pixel >> 16) & 0xFF;
          final g = (pixel >> 8) & 0xFF;
          final b = pixel & 0xFF;
          final color = Color.fromARGB(255, r, g, b);
          final hsl = HSLColor.fromColor(color);
          // Ignore very light, very dark, and low-saturation pixels
          if (hsl.lightness < 0.15 || hsl.lightness > 0.85) continue;
          if (hsl.saturation < 0.25) continue;
          if (hsl.saturation > maxSaturation) {
            maxSaturation = hsl.saturation;
            mostVibrant = color;
          }
        }
      }
      if (mostVibrant != null) {
        // Enhance vibrancy
        final hsl = HSLColor.fromColor(mostVibrant);
        return hsl
            .withSaturation((hsl.saturation * 1.2).clamp(0.5, 1.0))
            .withLightness((hsl.lightness * 0.9).clamp(0.25, 0.6))
            .toColor();
      }
      // Fallback: use a nice accent color if all pixels are grayscale
      return const Color(0xFF3A5A98); // Example: a vibrant blue
    } catch (e) {
      debugPrint('Error calculating dominant color: $e');
      return Colors.grey.shade800;
    }
  }

  // Optionally, add a method to clear the cache externally
  void clearCache() {
    _albumArtCache.clear();
    _dominantColorCache.clear();
  }
} 