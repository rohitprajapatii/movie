import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stage_movie/core/theme/app_theme.dart';
import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:stage_movie/presentation/blocs/movie_detail/movie_detail_bloc.dart';
import 'package:stage_movie/domain/usecases/get_movie_details_usecase.dart';
import 'package:stage_movie/domain/usecases/toggle_favorite_usecase.dart';
import 'package:stage_movie/main.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;
  final MovieModel? movie; // Optional movie data passed from list

  const MovieDetailScreen({Key? key, required this.movieId, this.movie})
    : super(key: key);

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _showOnlineBanner = false;
  Timer? _onlineBannerTimer;
  bool _isConnected = true; // Track previous connection state
  bool _isInitialLoad = true;
  ConnectivityStatus? _lastConnectivityState;
  bool _hasChangedFavorite = false;

  @override
  void initState() {
    super.initState();
    // We'll load movie details in the BlocProvider.create callback
  }

  // Process connectivity state change outside of build method
  void _processConnectivityChange(ConnectivityStatus state) {
    // Don't process the same state multiple times
    if (_lastConnectivityState?.isConnected == state.isConnected) return;
    _lastConnectivityState = state;

    if (!state.isConnected && _isConnected) {
      // Transition from online to offline
      _isConnected = false;
      if (mounted) {
        setState(() {
          _showOnlineBanner = false;
        });
      }

      // No need to reload data here - user will see offline message
    } else if (state.isConnected && !_isConnected) {
      // Transition from offline to online
      _isConnected = true;

      if (mounted) {
        setState(() {
          _showOnlineBanner = true;
        });
      }

      // Schedule auto-dismiss after 3 seconds
      _onlineBannerTimer?.cancel();
      _onlineBannerTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showOnlineBanner = false;
          });
        }
      });

      // Initial load if needed
      if (_isInitialLoad) {
        _isInitialLoad = false;
        Future.delayed(const Duration(milliseconds: 100), () {
          // Delay slightly to avoid build conflicts
          if (mounted) {
            context.read<MovieDetailBloc>().add(
              LoadMovieDetail(widget.movieId),
            );
          }
        });
      } else {
        // Reload data after coming back online
        Future.delayed(const Duration(milliseconds: 100), () {
          // Delay slightly to avoid build conflicts
          if (mounted) {
            context.read<MovieDetailBloc>().add(
              LoadMovieDetail(widget.movieId),
            );
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _onlineBannerTimer?.cancel();
    super.dispose();
  }

  // Helper method to handle back navigation
  void _handleBackNavigation(BuildContext context) {
    final bloc = BlocProvider.of<MovieDetailBloc>(context);
    bool hasChanged = bloc.hasFavoriteChanged;

    // Get the current movie state if available
    MovieModel? updatedMovie;
    if (bloc.state is MovieDetailLoaded) {
      updatedMovie = (bloc.state as MovieDetailLoaded).movie;

      // Debug output
      print('DEBUG: Returning from detail screen');
      print('DEBUG: Movie ID: ${updatedMovie.id}');
      print('DEBUG: Favorite Status: ${updatedMovie.isFavorite}');

      // Always return with current data - this ensures we always update the list
      GoRouter.of(context).pop({
        'movieId': updatedMovie.id,
        'isFavorite': updatedMovie.isFavorite,
        'hasChanged': true,
      });
      return;
    }

    // Reset flag
    bloc.checkAndResetFavoriteChanged();

    // If no loaded state available, just return
    GoRouter.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Access dependencies from the AppDependencies InheritedWidget without listening
    final dependencies = AppDependencies.of(context, listen: false);
    final getMovieDetailsUseCase = dependencies.getMovieDetailsUseCase;
    final toggleFavoriteUseCase = dependencies.toggleFavoriteUseCase;

    return BlocProvider(
      create: (context) {
        // Create a new MovieDetailBloc instance for this screen
        final bloc = MovieDetailBloc(
          getMovieDetailsUseCase,
          toggleFavoriteUseCase,
        );

        // Immediately load the movie details
        bloc.add(LoadMovieDetail(widget.movieId));
        return bloc;
      },
      // Using Builder to get a context that has access to the bloc
      child: Builder(
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              _handleBackNavigation(context);
              return false; // We'll handle the navigation ourselves
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(widget.movie?.title ?? 'Movie Details'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBackNavigation(context),
                ),
              ),
              body: BlocConsumer<MovieDetailBloc, MovieDetailState>(
                listener: (context, state) {
                  // Listen for favorite status changes
                  if (state is MovieDetailLoaded) {
                    if (widget.movie != null &&
                        widget.movie!.isFavorite != state.movie.isFavorite) {
                      // Favorite status changed
                      _hasChangedFavorite = true;
                      print(
                        'DEBUG: Favorite status changed to: ${state.movie.isFavorite}',
                      );
                    }
                  }
                },
                builder: (context, state) {
                  // If we have preliminary data from navigation, show it while loading
                  if (state is MovieDetailInitial && widget.movie != null) {
                    return _buildMovieContent(widget.movie!);
                  } else if (state is MovieDetailLoading &&
                      widget.movie != null) {
                    return _buildMovieContent(widget.movie!);
                  } else if (state is MovieDetailLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is MovieDetailLoaded) {
                    return _buildMovieContent(state.movie);
                  } else if (state is MovieDetailError) {
                    return _buildErrorView(state.message);
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMovieContent(MovieModel movie) {
    return CustomScrollView(
      slivers: [
        _buildDetailHeader(movie),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOfflineBanner(),
              _buildMovieInfo(movie),
              _buildOverview(movie),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailHeader(MovieModel movie) {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) {
          return Stack(
            children: [
              // Backdrop image with gradient overlay
              Hero(
                tag: 'movie_backdrop_${movie.id}',
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: movie.fullBackdropPath,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: AppTheme.cardColor,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: AppTheme.cardColor,
                              child: const Icon(
                                Icons.error,
                                color: AppTheme.errorColor,
                              ),
                            ),
                      ),
                      // Gradient overlay for better readability
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Favorite button overlay
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      movie.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: movie.isFavorite ? Colors.red : Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      final bloc = BlocProvider.of<MovieDetailBloc>(context);
                      bloc.add(ToggleDetailFavorite(movie));
                    },
                  ),
                ),
              ),

              // Title overlay
              Positioned(
                bottom: 16,
                left: 16,
                right: 48,
                child: Text(
                  movie.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Builder(
      builder: (context) {
        // Simple offline banner based on passed isConnected state
        if (!_isConnected) {
          // Show offline banner
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are offline. Some features may be unavailable.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else if (_showOnlineBanner) {
          // Show online banner if flag is set
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.green,
            child: Row(
              children: [
                const Icon(Icons.wifi, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are back online!',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    BlocProvider.of<MovieDetailBloc>(
                      context,
                    ).add(LoadMovieDetail(widget.movieId));
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMovieInfo(MovieModel movie) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Hero(
              tag: 'movie_poster_${movie.id}',
              child: CachedNetworkImage(
                imageUrl: movie.fullPosterPath,
                width: 120,
                height: 180,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: AppTheme.cardColor,
                      width: 120,
                      height: 180,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: AppTheme.cardColor,
                      width: 120,
                      height: 180,
                      child: const Icon(
                        Icons.error,
                        color: AppTheme.errorColor,
                      ),
                    ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Movie details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (movie.releaseDate != null && movie.releaseDate!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Released: ${movie.releaseDate}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${movie.voteAverage.toStringAsFixed(1)}/10',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(MovieModel movie) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(movie.overview, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Builder(
      builder: (context) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading movie details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Use the Builder's context which has access to the BlocProvider
                  BlocProvider.of<MovieDetailBloc>(
                    context,
                  ).add(LoadMovieDetail(widget.movieId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        );
      },
    );
  }
}
