import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/data/repositories/movie_repository.dart';

class GetMoviesUseCase {
  final MovieRepository _repository;

  GetMoviesUseCase(this._repository);

  Future<List<MovieModel>> getTrendingMovies() async {
    return _repository.getTrendingMovies();
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    return _repository.searchMovies(query);
  }

  Future<List<MovieModel>> getFavoriteMovies() async {
    return _repository.getFavoriteMovies();
  }
}
