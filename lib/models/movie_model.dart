import '../utils/constants.dart';

/// Movie model with hand-written fromJson/toJson (no code generation needed).
/// Handles BOTH the VidAPI response format AND the legacy mock-data format.
class Movie {
  final String? id;
  final String? title;
  final String? originalTitle;
  final int? year;
  final String? kpId;
  final String? imdbId;
  final String? tmdbId;
  final String? posterUrl;
  final String? embedUrl;
  final String? description;
  final double? rating;
  final int? votes;
  final List<String>? genres;
  final List<String>? countries;
  final String? type; // 'movie' or 'tv' or 'tvshow' or 'episode'
  final int? duration;
  final String? director;
  final List<String>? cast;

  // Extra fields for enhanced features
  final String? trailerUrl;
  final String? backdropUrl;
  final int? seasons;
  final List<int>? episodesPerSeason;
  final bool? isTrending;
  final double? popularity;

  // Episode-specific fields (from VidAPI episodes endpoint)
  final String? showTitle;      // parent show title
  final String? showImdbId;     // parent show IMDB ID
  final String? showTmdbId;     // parent show TMDB ID
  final int? seasonNumber;
  final int? episodeNumber;
  final String? episodeTitle;
  final String? airDate;

  Movie({
    this.id,
    this.title,
    this.originalTitle,
    this.year,
    this.kpId,
    this.imdbId,
    this.tmdbId,
    this.posterUrl,
    this.embedUrl,
    this.description,
    this.rating,
    this.votes,
    this.genres,
    this.countries,
    this.type = 'movie',
    this.duration,
    this.director,
    this.cast,
    this.trailerUrl,
    this.backdropUrl,
    this.seasons,
    this.episodesPerSeason,
    this.isTrending,
    this.popularity,
    this.showTitle,
    this.showImdbId,
    this.showTmdbId,
    this.seasonNumber,
    this.episodeNumber,
    this.episodeTitle,
    this.airDate,
  });

  // ─── Hand-written fromJson ────────────────────────────────────────────────
  /// Parses both VidAPI format AND legacy mock-data format.
  factory Movie.fromJson(Map<String, dynamic> json) {
    // ── Year: VidAPI returns "2023" (String), mock returns 2023 (int) ──
    int? yearValue;
    final rawYear = json['year'];
    if (rawYear is int) {
      yearValue = rawYear;
    } else if (rawYear is String) {
      yearValue = int.tryParse(rawYear);
    }

    // ── Rating: VidAPI returns "7.1" (String), mock returns 9.3 (double) ──
    double? ratingValue;
    final rawRating = json['rating'];
    if (rawRating is num) {
      ratingValue = rawRating.toDouble();
    } else if (rawRating is String) {
      ratingValue = double.tryParse(rawRating);
    }

    // ── Popularity: VidAPI returns "2847.12" (String) ──
    double? popularityValue;
    final rawPopularity = json['popularity'];
    if (rawPopularity is num) {
      popularityValue = rawPopularity.toDouble();
    } else if (rawPopularity is String) {
      popularityValue = double.tryParse(rawPopularity);
    }

    // ── Genres: VidAPI returns "Action, Crime, Thriller" (String),
    //    mock returns ["Drama", "Crime"] (List) ──
    List<String>? genresValue;
    final rawGenre = json['genre'];       // VidAPI uses "genre" (string)
    final rawGenres = json['genres'];     // legacy uses "genres" (list)
    if (rawGenres is List) {
      genresValue = rawGenres.map((e) => e.toString()).toList();
    } else if (rawGenre is String && rawGenre.isNotEmpty) {
      genresValue = rawGenre.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    // ── Episode fields: VidAPI episodes endpoint uses different keys ──
    // show_tmdb_id, show_imdb_id, season_number, episode_number,
    // episode_title, air_date, show_title
    final episodeImdbId = json['show_imdb_id'] as String?;
    final episodeTmdbId = json['show_tmdb_id'] as String?;
    final seasonNum = json['season_number'];
    final episodeNum = json['episode_number'];

    int? seasonNumberValue;
    if (seasonNum is int) {
      seasonNumberValue = seasonNum;
    } else if (seasonNum is String) {
      seasonNumberValue = int.tryParse(seasonNum);
    }

    int? episodeNumberValue;
    if (episodeNum is int) {
      episodeNumberValue = episodeNum;
    } else if (episodeNum is String) {
      episodeNumberValue = int.tryParse(episodeNum);
    }

    // Determine the effective IDs - for episodes, use the show's IDs
    final effectiveImdbId = json['imdb_id'] as String? ?? episodeImdbId;
    final effectiveTmdbId = json['tmdb_id'] as String? ?? episodeTmdbId;

    // For episodes, the display title should be show_title
    final effectiveTitle = json['title'] as String? ?? json['show_title'] as String?;

    // Determine the type
    String typeValue = json['type'] as String? ?? 'movie';
    // Normalize type: VidAPI uses "tv" for TV shows, legacy uses "tvshow"
    if (typeValue == 'tv') typeValue = 'tvshow';

    return Movie(
      id: json['id'] as String?,
      title: effectiveTitle,
      originalTitle: json['original_title'] as String?,
      year: yearValue,
      kpId: json['kp_id'] as String?,
      imdbId: effectiveImdbId,
      tmdbId: effectiveTmdbId,
      posterUrl: json['poster_url'] as String?,
      embedUrl: json['embed_url'] as String?,
      description: json['description'] as String?,
      rating: ratingValue,
      votes: json['votes'] as int?,
      genres: genresValue,
      countries: (json['countries'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      type: typeValue,
      duration: json['duration'] as int?,
      director: json['director'] as String?,
      cast: (json['cast'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      trailerUrl: json['trailer_url'] as String?,
      backdropUrl: json['backdrop_url'] as String?,
      seasons: json['seasons'] as int?,
      episodesPerSeason: (json['episodes_per_season'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      isTrending: json['is_trending'] as bool?,
      popularity: popularityValue,
      showTitle: json['show_title'] as String?,
      showImdbId: episodeImdbId,
      showTmdbId: episodeTmdbId,
      seasonNumber: seasonNumberValue,
      episodeNumber: episodeNumberValue,
      episodeTitle: json['episode_title'] as String?,
      airDate: json['air_date'] as String?,
    );
  }

  // ─── Hand-written toJson ──────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'original_title': originalTitle,
      'year': year,
      'kp_id': kpId,
      'imdb_id': imdbId,
      'tmdb_id': tmdbId,
      'poster_url': posterUrl,
      'embed_url': embedUrl,
      'description': description,
      'rating': rating,
      'votes': votes,
      'genres': genres,
      'countries': countries,
      'type': type,
      'duration': duration,
      'director': director,
      'cast': cast,
      'trailer_url': trailerUrl,
      'backdrop_url': backdropUrl,
      'seasons': seasons,
      'episodes_per_season': episodesPerSeason,
      'is_trending': isTrending,
      'popularity': popularity,
      'show_title': showTitle,
      'show_imdb_id': showImdbId,
      'show_tmdb_id': showTmdbId,
      'season_number': seasonNumber,
      'episode_number': episodeNumber,
      'episode_title': episodeTitle,
      'air_date': airDate,
    };
  }

  // ─── Helper methods ───────────────────────────────────────────────────────

  /// Returns the number of episodes in a given season (1-indexed).
  /// Falls back to 999 so navigation never gets stuck when data is missing.
  int getEpisodesInSeason(int season) {
    if (episodesPerSeason != null && season >= 1 && season <= episodesPerSeason!.length) {
      return episodesPerSeason![season - 1];
    }
    return 999;
  }

  /// Display title: for episodes, show "Show Title - S01E01: Episode Title"
  String get displayTitle {
    if (isEpisode) {
      final showName = showTitle ?? title ?? 'Unknown';
      if (episodeTitle != null && episodeTitle!.isNotEmpty) {
        return '$showName - $episodeTitle';
      }
      return showName;
    }
    return title ?? originalTitle ?? 'Unknown';
  }

  /// Short display title for cards (just the main title)
  String get shortDisplayTitle {
    if (isEpisode) {
      return showTitle ?? title ?? 'Unknown';
    }
    return title ?? originalTitle ?? 'Unknown';
  }

  bool get isTV => type == 'tvshow' || type == 'tv';
  bool get isEpisode => type == 'episode';
  bool get isMovie => type == 'movie';
  String get ratingDisplay => rating != null ? rating!.toStringAsFixed(1) : 'N/A';
  String get yearDisplay => year?.toString() ?? 'Unknown Year';
  String get uniqueId => imdbId ?? tmdbId ?? id ?? '';

  /// Season/Episode display string
  String get seasonEpisodeDisplay {
    if (seasonNumber != null && episodeNumber != null) {
      return 'S${seasonNumber.toString().padLeft(2, '0')}E${episodeNumber.toString().padLeft(2, '0')}';
    }
    return '';
  }

  // Get player URL
  String getPlayerUrl({bool isTV = false, int season = 1, int episode = 1}) {
    // Safety check: if all IDs are null, return empty string to prevent broken WebView loads
    if (imdbId == null && tmdbId == null && kpId == null) return '';

    final id = imdbId ?? tmdbId ?? kpId ?? '';

    if (isTV || isEpisode) {
      return '${AppConstants.vaPlayerBaseUrl}/tv/$id/$season/$episode?ds_lang=ar&primaryColor=%23E50914';
    } else {
      return '${AppConstants.vaPlayerBaseUrl}/movie/$id?ds_lang=ar&primaryColor=%23E50914';
    }
  }

  // Get genres as comma-separated string
  String get genresDisplay => genres?.join(', ') ?? '';

  // Get duration display
  String get durationDisplay {
    if (duration == null) return '';
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

/// Response wrapper – supports both "items" (VidAPI) and "result" (legacy) keys.
/// Also parses pagination data from VidAPI format.
class MovieResponse {
  final List<Movie>? result;
  final Pagination? pagination;

  MovieResponse({
    this.result,
    this.pagination,
  });

  factory MovieResponse.fromJson(Map<String, dynamic> json) {
    // Support both "items" (VidAPI) and "result" (legacy) keys
    final List<dynamic>? rawList =
        (json['items'] as List<dynamic>?) ?? (json['result'] as List<dynamic>?);

    // Parse pagination from VidAPI format
    Pagination? paginationValue;
    if (json['pagination'] != null) {
      paginationValue = Pagination.fromJson(json['pagination'] as Map<String, dynamic>);
    } else if (json['page'] != null) {
      // VidAPI format: page, per_page, total, total_pages
      paginationValue = Pagination(
        currentPage: json['page'] as int?,
        totalPages: json['total_pages'] as int?,
        totalResults: json['total'] as int?,
      );
    }

    return MovieResponse(
      result: rawList
          ?.map((item) => Movie.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: paginationValue,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'result': result?.map((m) => m.toJson()).toList(),
      'pagination': pagination?.toJson(),
    };
  }
}

/// Pagination metadata
class Pagination {
  final int? currentPage;
  final int? totalPages;
  final int? totalResults;

  Pagination({
    this.currentPage,
    this.totalPages,
    this.totalResults,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['currentPage'] as int? ?? json['page'] as int?,
      totalPages: json['totalPages'] as int? ?? json['total_pages'] as int?,
      totalResults: json['totalResults'] as int? ?? json['total'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalResults': totalResults,
    };
  }
}
