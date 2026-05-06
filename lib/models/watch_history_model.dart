import 'movie_model.dart';

/// Watch history entry model with hand-written fromJson/toJson.
class WatchHistoryEntry {
  final Movie movie;
  final int position; // in seconds
  final int duration; // total duration in seconds
  final int season;
  final int episode;
  final DateTime lastWatched;

  WatchHistoryEntry({
    required this.movie,
    required this.position,
    required this.duration,
    this.season = 1,
    this.episode = 1,
    DateTime? lastWatched,
  }) : lastWatched = lastWatched ?? DateTime.now();

  /// Get progress as a percentage
  double get progress => duration > 0 ? position / duration : 0.0;

  /// Get progress percentage display
  String get progressDisplay => '${(progress * 100).toInt()}%';

  /// Get season/episode display
  String get episodeDisplay => movie.isTV ? 'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')}' : '';

  /// Check if mostly watched (>90%)
  bool get isCompleted => progress > 0.9;

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) {
    return WatchHistoryEntry(
      movie: Movie.fromJson(json['movie'] as Map<String, dynamic>),
      position: json['position'] as int,
      duration: json['duration'] as int,
      season: json['season'] as int? ?? 1,
      episode: json['episode'] as int? ?? 1,
      lastWatched: json['lastWatched'] == null
          ? null
          : DateTime.parse(json['lastWatched'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'movie': movie.toJson(),
      'position': position,
      'duration': duration,
      'season': season,
      'episode': episode,
      'lastWatched': lastWatched.toIso8601String(),
    };
  }
}
