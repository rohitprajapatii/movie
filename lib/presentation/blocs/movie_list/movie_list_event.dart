part of 'movie_list_bloc.dart';

abstract class MovieListEvent extends Equatable {
  const MovieListEvent();

  @override
  List<Object?> get props => [];
}

class LoadTrendingMovies extends MovieListEvent {}

class LoadFavoriteMovies extends MovieListEvent {}

class SearchMovies extends MovieListEvent {
  final String query;

  const SearchMovies(this.query);

  @override
  List<Object> get props => [query];
}

class ToggleMovieFavorite extends MovieListEvent {
  final MovieModel movie;

  const ToggleMovieFavorite(this.movie);

  @override
  List<Object> get props => [movie];
}

class UpdateMovieFavoriteStatus extends MovieListEvent {
  final int movieId;
  final bool isFavorite;

  const UpdateMovieFavoriteStatus({
    required this.movieId,
    required this.isFavorite,
  });

  @override
  List<Object> get props => [movieId, isFavorite];
}
