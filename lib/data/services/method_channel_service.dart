import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/song_model.dart';

class MethodChannelService {
  static const MethodChannel _channel = MethodChannel('com.musify/songs');

  static Future<List<Song>> getSongsFromDevice() async {
    try {
      final String result = await _channel.invokeMethod('getSongs');
      final List<dynamic> songsJson = json.decode(result);
      
      return songsJson.map((json) => Song.fromJson(json)).toList();
    } on PlatformException catch (e) {
      print('Error fetching songs: ${e.message}');
      return [];
    } catch (e) {
      print('Unexpected error: $e');
      return [];
    }
  }
} 