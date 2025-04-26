import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/domain/usecases/get_movies_usecase.dart';
import 'package:stage_movie/domain/usecases/toggle_favorite_usecase.dart';

part 'movie_list_event.dart';
part 'movie_list_state.dart';

class MovieListBloc extends Bloc<MovieListEvent, MovieListState> {
  final GetMoviesUseCase _getMoviesUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;

  MovieListBloc(this._getMoviesUseCase, this._toggleFavoriteUseCase)
    : super(MovieListInitial()) {
    on<LoadTrendingMovies>(_onLoadTrendingMovies);
    on<LoadFavoriteMovies>(_onLoadFavoriteMovies);
    on<SearchMovies>(_onSearchMovies);
    on<ToggleMovieFavorite>(_onToggleMovieFavorite);
    on<UpdateMovieFavoriteStatus>(_onUpdateMovieFavoriteStatus);
  }

  Future<void> _onLoadTrendingMovies(
    LoadTrendingMovies event,
    Emitter<MovieListState> emit,
  ) async {
    emit(MovieListLoading());
    try {
      final movies = await _getMoviesUseCase.getTrendingMovies();
      emit(MovieListLoaded(movies, isShowingFavorites: false));
    } catch (e) {
      emit(MovieListError(e.toString()));
    }
  }

  Future<void> _onLoadFavoriteMovies(
    LoadFavoriteMovies event,
    Emitter<MovieListState> emit,
  ) async {
    emit(MovieListLoading());
    try {
      final movies = await _getMoviesUseCase.getFavoriteMovies();
      emit(MovieListLoaded(movies, isShowingFavorites: true));
    } catch (e) {
      emit(MovieListError(e.toString()));
    }
  }

  Future<void> _onSearchMovies(
    SearchMovies event,
    Emitter<MovieListState> emit,
  ) async {
    emit(MovieListLoading());
    try {
      final movies = await _getMoviesUseCase.searchMovies(event.query);
      emit(
        MovieListLoaded(
          movies,
          isShowingFavorites: false,
          searchQuery: event.query,
        ),
      );
    } catch (e) {
      emit(MovieListError(e.toString()));
    }
  }

  Future<void> _onToggleMovieFavorite(
    ToggleMovieFavorite event,
    Emitter<MovieListState> emit,
  ) async {
    try {
      final isFavorite = await _toggleFavoriteUseCase.execute(event.movie);

      // Update the current state to reflect the change
      if (state is MovieListLoaded) {
        final currentState = state as MovieListLoaded;
        final updatedMovies =
            currentState.movies.map((movie) {
              if (movie.id == event.movie.id) {
                return movie.copyWith(isFavorite: isFavorite);
              }
              return movie;
            }).toList();

        emit(
          MovieListLoaded(
            updatedMovies,
            isShowingFavorites: currentState.isShowingFavorites,
            searchQuery: currentState.searchQuery,
          ),
        );

        // If we're showing favorites and the movie was unfavorited, we need to remove it
        if (currentState.isShowingFavorites && !isFavorite) {
          final filteredMovies =
              updatedMovies.where((movie) => movie.isFavorite).toList();
          emit(
            MovieListLoaded(
              filteredMovies,
              isShowingFavorites: true,
              searchQuery: currentState.searchQuery,
            ),
          );
        }
      }
    } catch (e) {
      // Don't change the UI state on error, just log it
      // If needed, we could add a SnackBar notification here
    }
  }

  // Update a single movie's favorite status without reloading the list
  Future<void> _onUpdateMovieFavoriteStatus(
    UpdateMovieFavoriteStatus event,
    Emitter<MovieListState> emit,
  ) async {
    if (state is MovieListLoaded) {
      final currentState = state as MovieListLoaded;
      final updatedMovies =
          currentState.movies.map((movie) {
            if (movie.id == event.movieId) {
              return movie.copyWith(isFavorite: event.isFavorite);
            }
            return movie;
          }).toList();

      // If showing favorites and movie was unfavorited, remove it
      if (currentState.isShowingFavorites && !event.isFavorite) {
        final filteredMovies =
            updatedMovies.where((movie) => movie.isFavorite).toList();
        emit(
          MovieListLoaded(
            filteredMovies,
            isShowingFavorites: true,
            searchQuery: currentState.searchQuery,
          ),
        );
      } else {
        // Otherwise just update the list
        emit(
          MovieListLoaded(
            updatedMovies,
            isShowingFavorites: currentState.isShowingFavorites,
            searchQuery: currentState.searchQuery,
          ),
        );
      }
    }
  }
}
