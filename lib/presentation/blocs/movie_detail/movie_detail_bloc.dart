import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/domain/usecases/get_movie_details_usecase.dart';
import 'package:stage_movie/domain/usecases/toggle_favorite_usecase.dart';

part 'movie_detail_event.dart';
part 'movie_detail_state.dart';

class MovieDetailBloc extends Bloc<MovieDetailEvent, MovieDetailState> {
  final GetMovieDetailsUseCase _getMovieDetailsUseCase;
  final ToggleFavoriteUseCase _toggleFavoriteUseCase;
  bool hasFavoriteChanged = false;

  MovieDetailBloc(this._getMovieDetailsUseCase, this._toggleFavoriteUseCase)
    : super(MovieDetailInitial()) {
    on<LoadMovieDetail>(_onLoadMovieDetail);
    on<ToggleDetailFavorite>(_onToggleDetailFavorite);
  }

  Future<void> _onLoadMovieDetail(
    LoadMovieDetail event,
    Emitter<MovieDetailState> emit,
  ) async {
    emit(MovieDetailLoading());
    try {
      final movie = await _getMovieDetailsUseCase.execute(event.movieId);
      emit(MovieDetailLoaded(movie));
    } catch (e) {
      emit(MovieDetailError(e.toString()));
    }
  }

  Future<void> _onToggleDetailFavorite(
    ToggleDetailFavorite event,
    Emitter<MovieDetailState> emit,
  ) async {
    try {
      final isFavorite = await _toggleFavoriteUseCase.execute(event.movie);
      hasFavoriteChanged =
          true; // Set flag to indicate favorite status has changed

      if (state is MovieDetailLoaded) {
        final currentState = state as MovieDetailLoaded;
        // Update the movie in the state with the new favorite value
        final updatedMovie = currentState.movie.copyWith(
          isFavorite: isFavorite,
        );
        emit(MovieDetailLoaded(updatedMovie));
      }
    } catch (e) {
      // Don't change the UI state on error, just log it
    }
  }

  // Method to check and reset favorite changed status
  bool checkAndResetFavoriteChanged() {
    final changed = hasFavoriteChanged;
    hasFavoriteChanged = false;
    return changed;
  }
}
