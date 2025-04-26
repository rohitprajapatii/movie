import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/data/repositories/movie_repository.dart';

class ToggleFavoriteUseCase {
  final MovieRepository _repository;

  ToggleFavoriteUseCase(this._repository);

  Future<bool> execute(MovieModel movie) async {
    return _repository.toggleFavorite(movie);
  }
}
