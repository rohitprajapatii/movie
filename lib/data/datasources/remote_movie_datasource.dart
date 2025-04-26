import 'package:dio/dio.dart';
import 'package:stage_movie/core/config/app_constants.dart';
import 'package:stage_movie/core/services/network_service.dart';
import 'package:stage_movie/data/models/movie_model.dart';

class RemoteMovieDataSource {
  final NetworkService _networkService;

  RemoteMovieDataSource(this._networkService);

  Future<List<MovieModel>> getTrendingMovies() async {
    try {
      final response = await _networkService.get(
        AppConstants.trendingMoviesEndpoint,
      );

      final List<dynamic> moviesJson = response.data['results'];
      return moviesJson.map((json) => MovieModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<MovieModel> getMovieDetails(int movieId) async {
    try {
      final response = await _networkService.get(
        '${AppConstants.movieDetailsEndpoint}$movieId',
      );

      return MovieModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      final response = await _networkService.get(
        AppConstants.searchMoviesEndpoint,
        queryParameters: {'query': query},
      );

      final List<dynamic> moviesJson = response.data['results'];
      return moviesJson.map((json) => MovieModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}
