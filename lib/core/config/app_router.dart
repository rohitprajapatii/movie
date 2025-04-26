import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/presentation/screens/movie_detail_screen.dart';
import 'package:stage_movie/presentation/screens/movie_list_screen.dart';

class AppRouter {
  static const String homeRoute = '/';
  static const String detailRoute = '/movie/:id';

  static GoRouter router = GoRouter(
    initialLocation: homeRoute,
    routes: [
      GoRoute(
        path: homeRoute,
        builder: (context, state) => const MovieListScreen(),
      ),
      GoRoute(
        path: detailRoute,
        builder: (context, state) {
          // Get the movie ID from the URL parameters
          final String movieId = state.pathParameters['id'] ?? '0';

          // If movie details were passed via state, use them
          final MovieModel? movie = state.extra as MovieModel?;

          // Create MovieDetailScreen with the necessary data
          return MovieDetailScreen(
            movieId: int.parse(movieId),
            movie: movie, // This could be null initially
          );
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Not Found')),
          body: Center(child: Text('No route found for ${state.uri.path}')),
        ),
  );
}
