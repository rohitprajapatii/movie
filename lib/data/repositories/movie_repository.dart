import 'package:stage_movie/core/services/connectivity_service.dart';
import 'package:stage_movie/core/utils/error_handler.dart';
import 'package:stage_movie/data/datasources/local_movie_datasource.dart';
import 'package:stage_movie/data/datasources/remote_movie_datasource.dart';
import 'package:stage_movie/data/models/movie_model.dart';

class MovieRepository {
  final RemoteMovieDataSource _remoteDataSource;
  final LocalMovieDataSource _localDataSource;
  final ConnectivityService _connectivityService;

  MovieRepository(
    this._remoteDataSource,
    this._localDataSource,
    this._connectivityService,
  );

  Future<List<MovieModel>> getTrendingMovies() async {
    try {
      final isConnected = await _connectivityService.isConnected();

      if (isConnected) {
        final movies = await _remoteDataSource.getTrendingMovies();

        // Check which movies are favorites
        final favoriteMovies = await _localDataSource.getFavoriteMovies();
        final favoriteIds = favoriteMovies.map((movie) => movie.id).toSet();

        return movies.map((movie) {
          return movie.copyWith(isFavorite: favoriteIds.contains(movie.id));
        }).toList();
      } else {
        // If offline, return only favorite movies
        return _localDataSource.getFavoriteMovies();
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<MovieModel> getMovieDetails(int movieId) async {
    try {
      final isConnected = await _connectivityService.isConnected();

      if (isConnected) {
        final movie = await _remoteDataSource.getMovieDetails(movieId);

        // Check if movie is favorite
        final isFavorite = await _localDataSource.isFavorite(movieId);
        return movie.copyWith(isFavorite: isFavorite);
      } else {
        // If offline, try to get movie from favorites
        final favoriteMovies = await _localDataSource.getFavoriteMovies();
        final movie = favoriteMovies.firstWhere(
          (movie) => movie.id == movieId,
          orElse: () => throw Exception('Movie not found in offline mode'),
        );
        return movie;
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<MovieModel>> searchMovies(String query) async {
    try {
      final isConnected = await _connectivityService.isConnected();

      if (isConnected) {
        final movies = await _remoteDataSource.searchMovies(query);

        // Check which movies are favorites
        final favoriteMovies = await _localDataSource.getFavoriteMovies();
        final favoriteIds = favoriteMovies.map((movie) => movie.id).toSet();

        return movies.map((movie) {
          return movie.copyWith(isFavorite: favoriteIds.contains(movie.id));
        }).toList();
      } else {
        // If offline, search only in favorite movies
        final favoriteMovies = await _localDataSource.getFavoriteMovies();
        return favoriteMovies
            .where(
              (movie) =>
                  movie.title.toLowerCase().contains(query.toLowerCase()) ||
                  movie.overview.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<bool> toggleFavorite(MovieModel movie) async {
    return await _localDataSource.toggleFavorite(movie);
  }

  Future<List<MovieModel>> getFavoriteMovies() async {
    return _localDataSource.getFavoriteMovies();
  }

  // Method to check if a movie is a favorite
  Future<bool> isFavorite(int movieId) async {
    return _localDataSource.isFavorite(movieId);
  }
}
