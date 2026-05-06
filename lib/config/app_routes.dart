import 'package:get/get.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/player_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/downloads_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/browse_all_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String search = '/search';
  static const String movieDetail = '/movie-detail';
  static const String player = '/player';
  static const String watchlist = '/watchlist';
  static const String downloads = '/downloads';
  static const String settings = '/settings';
  static const String browseAll = '/browse-all';

  static final List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name: movieDetail,
      page: () => const MovieDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: player,
      page: () => const PlayerScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: watchlist,
      page: () => const WatchlistScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: downloads,
      page: () => const DownloadsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: browseAll,
      page: () => const BrowseAllScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
