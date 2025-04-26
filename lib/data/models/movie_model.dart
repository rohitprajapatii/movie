import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'movie_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class MovieModel extends HiveObject {
  @JsonKey(name: 'id')
  @HiveField(0)
  final int id;

  @JsonKey(name: 'title')
  @HiveField(1)
  final String title;

  @JsonKey(name: 'overview')
  @HiveField(2)
  final String overview;

  @JsonKey(name: 'poster_path')
  @HiveField(3)
  final String? posterPath;

  @JsonKey(name: 'backdrop_path')
  @HiveField(4)
  final String? backdropPath;

  @JsonKey(name: 'vote_average')
  @HiveField(5)
  final double voteAverage;

  @JsonKey(name: 'release_date')
  @HiveField(6)
  final String? releaseDate;

  @JsonKey(name: 'genre_ids')
  @HiveField(7)
  final List<int>? genreIds;

  @HiveField(8)
  bool isFavorite;

  MovieModel({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
    this.genreIds,
    this.isFavorite = false,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) =>
      _$MovieModelFromJson(json);

  Map<String, dynamic> toJson() => _$MovieModelToJson(this);

  String get fullPosterPath =>
      posterPath != null
          ? 'https://image.tmdb.org/t/p/w500$posterPath'
          : 'https://via.placeholder.com/500x750?text=No+Poster';

  String get fullBackdropPath =>
      backdropPath != null
          ? 'https://image.tmdb.org/t/p/original$backdropPath'
          : 'https://via.placeholder.com/1280x720?text=No+Backdrop';

  String get year =>
      releaseDate != null && releaseDate!.isNotEmpty
          ? releaseDate!.substring(0, 4)
          : 'Unknown';

  // Create a copy with updated isFavorite value
  MovieModel copyWith({bool? isFavorite}) {
    return MovieModel(
      id: id,
      title: title,
      overview: overview,
      posterPath: posterPath,
      backdropPath: backdropPath,
      voteAverage: voteAverage,
      releaseDate: releaseDate,
      genreIds: genreIds,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
