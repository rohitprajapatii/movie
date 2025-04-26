import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/data/repositories/movie_repository.dart';

class GetMovieDetailsUseCase {
  final MovieRepository _repository;

  GetMovieDetailsUseCase(this._repository);

  Future<MovieModel> execute(int movieId) async {
    return _repository.getMovieDetails(movieId);
  }
}
