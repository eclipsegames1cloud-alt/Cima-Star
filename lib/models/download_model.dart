import 'movie_model.dart';

/// Download item model with hand-written fromJson/toJson.
class DownloadItem {
  final Movie movie;
  final String localPath;
  final int fileSize;
  final DateTime downloadDate;
  final DownloadStatus status;

  DownloadItem({
    required this.movie,
    required this.localPath,
    required this.fileSize,
    DateTime? downloadDate,
    this.status = DownloadStatus.completed,
  }) : downloadDate = downloadDate ?? DateTime.now();

  /// Get file size in readable format
  String get fileSizeDisplay {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1048576) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1073741824) return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
    return '${(fileSize / 1073741824).toStringAsFixed(1)} GB';
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      movie: Movie.fromJson(json['movie'] as Map<String, dynamic>),
      localPath: json['localPath'] as String,
      fileSize: json['fileSize'] as int,
      downloadDate: json['downloadDate'] == null
          ? null
          : DateTime.parse(json['downloadDate'] as String),
      status: _parseDownloadStatus(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'movie': movie.toJson(),
      'localPath': localPath,
      'fileSize': fileSize,
      'downloadDate': downloadDate.toIso8601String(),
      'status': status.name,
    };
  }

  static DownloadStatus _parseDownloadStatus(String? value) {
    switch (value) {
      case 'pending': return DownloadStatus.pending;
      case 'downloading': return DownloadStatus.downloading;
      case 'completed': return DownloadStatus.completed;
      case 'failed': return DownloadStatus.failed;
      case 'paused': return DownloadStatus.paused;
      default: return DownloadStatus.completed;
    }
  }
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  paused,
}
