import 'package:get/get.dart';
import 'player_controller.dart';
import 'song_controller.dart';
import 'favorite_controller.dart';

class MusicController extends GetxController {
  // Getters to access lazily initialized controllers
  PlayerController get playerController => Get.find<PlayerController>();
  SongController get songController => Get.find<SongController>();
  FavoriteController get favoriteController => Get.find<FavoriteController>();

  @override
  void onInit() {
    super.onInit();
    // No need to initialize here; bindings will handle it
  }

  @override
  void onClose() {
    Get.delete<PlayerController>();
    Get.delete<SongController>();
    Get.delete<FavoriteController>();
    super.onClose();
  }
}
