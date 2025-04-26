part of 'movie_list_bloc.dart';

abstract class MovieListState extends Equatable {
  const MovieListState();

  @override
  List<Object?> get props => [];
}

class MovieListInitial extends MovieListState {}

class MovieListLoading extends MovieListState {}

class MovieListLoaded extends MovieListState {
  final List<MovieModel> movies;
  final bool isShowingFavorites;
  final String? searchQuery;

  const MovieListLoaded(
    this.movies, {
    required this.isShowingFavorites,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [movies, isShowingFavorites, searchQuery];
}

class MovieListError extends MovieListState {
  final String message;

  const MovieListError(this.message);

  @override
  List<Object> get props => [message];
}
