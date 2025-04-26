part of 'movie_detail_bloc.dart';

abstract class MovieDetailEvent extends Equatable {
  const MovieDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadMovieDetail extends MovieDetailEvent {
  final int movieId;

  const LoadMovieDetail(this.movieId);

  @override
  List<Object> get props => [movieId];
}

class ToggleDetailFavorite extends MovieDetailEvent {
  final MovieModel movie;

  const ToggleDetailFavorite(this.movie);

  @override
  List<Object> get props => [movie];
}
