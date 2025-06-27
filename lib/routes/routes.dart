import 'package:get/get.dart';
import 'package:musify/controllers/music_controller.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/views/home_screen.dart';
import 'package:musify/views/search_page.dart';
import 'package:musify/views/song_list_page.dart';
import 'package:musify/views/now_playing_widget.dart';

class MusicBindings extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MusicController>(() => MusicController());
    Get.lazyPut<PlayerController>(() => PlayerController());
    Get.lazyPut<SongController>(() => SongController());
    Get.lazyPut<FavoriteController>(() => FavoriteController());
  }
}

class AppRoutes {
  static const HOME = '/home';
  static const SEARCH = '/search';
  static const SONG_LIST = '/song-list';
  static const NOW_PLAYING = '/now-playing';

  static final routes = [
    GetPage(
      name: HOME,
      page: () => const HomePage(),
      binding: MusicBindings(),
    ),
    GetPage(
      name: SEARCH,
      page: () => SearchPage(),
      binding: MusicBindings(),
    ),
    GetPage(
      name: SONG_LIST,
      page: () => SongListPage(title: 'Songs', songs: []),
      binding: MusicBindings(),
    ),
    GetPage(
      name: NOW_PLAYING,
      page: () => Get.find<MusicController>().nowPlayingWidget,
      binding: MusicBindings(),
    ),
  ];
}

// Extension to provide NowPlayingWidget with controllers
extension MusicControllerExtension on MusicController {
  NowPlayingWidget get nowPlayingWidget {
    return NowPlayingWidget(
      playerController: playerController,
      favoriteController: favoriteController,
      songController: songController,
      scrollController: null, // Can be customized if needed
    );
  }
}
