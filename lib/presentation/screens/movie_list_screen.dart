import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stage_movie/core/config/app_router.dart';
import 'package:stage_movie/core/theme/app_theme.dart';
import 'package:stage_movie/core/utils/debouncer.dart';
import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:stage_movie/presentation/blocs/movie_list/movie_list_bloc.dart';
import 'package:stage_movie/presentation/blocs/movie_detail/movie_detail_bloc.dart';
import 'package:stage_movie/presentation/widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({Key? key}) : super(key: key);

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer();
  bool _isShowingFavorites = false;
  bool _showOnlineBanner = false;
  Timer? _onlineBannerTimer;
  bool _isConnected = true; // Track previous connection state
  bool _isInitialLoad = true;
  ConnectivityStatus? _lastConnectivityState;
  DateTime? _lastNavigatedTime;

  @override
  void initState() {
    super.initState();

    // Check connectivity status
    context.read<ConnectivityBloc>().add(CheckConnectivity());

    // Initial data load is handled by connectivity state change
    // or will be done after connectivity check if no state change happens
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_isInitialLoad) {
        _isInitialLoad = false;
        context.read<MovieListBloc>().add(LoadTrendingMovies());
      }
    });

    // Add listener for search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set up a listener for route changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAfterRouteChange();
    });
  }

  // Refreshes the list when returning to this screen
  void _refreshAfterRouteChange() {
    // If we've navigated back to this screen after some time
    DateTime now = DateTime.now();
    if (_lastNavigatedTime != null &&
        now.difference(_lastNavigatedTime!).inSeconds > 1) {
      // We no longer refresh the entire list on screen return
      // The favorite status updates will be handled by the return value
      // from the detail screen via the _navigateToDetail method
    }
    _lastNavigatedTime = now;
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

      // Initial load of movies if needed
      if (_isInitialLoad) {
        _isInitialLoad = false;
        Future.delayed(const Duration(milliseconds: 100), () {
          // Delay slightly to avoid build conflicts
          if (mounted) {
            if (_isShowingFavorites) {
              context.read<MovieListBloc>().add(LoadFavoriteMovies());
            } else {
              context.read<MovieListBloc>().add(LoadTrendingMovies());
            }
          }
        });
      }
      // We remove the reload when coming back online, as it's not necessary
      // unless the user explicitly requests a refresh
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _debouncer.cancel();
      if (_isShowingFavorites) {
        context.read<MovieListBloc>().add(LoadFavoriteMovies());
      } else {
        context.read<MovieListBloc>().add(LoadTrendingMovies());
      }
    } else {
      _debouncer.run(() {
        context.read<MovieListBloc>().add(SearchMovies(_searchController.text));
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debouncer.cancel();
    _onlineBannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage Movie'),
        actions: [_buildFavoritesToggle()],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildConnectivityBanner(),
          Expanded(child: _buildMovieList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search movies...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white10,
        ),
      ),
    );
  }

  Widget _buildConnectivityBanner() {
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityStatus) {
          // Schedule a callback after the current build is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _processConnectivityChange(state);
          });
        }
      },
      child: Builder(
        builder: (context) {
          // Display appropriate banner based on current state variables
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
                      'You are offline. Only favorite movies are available.',
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
                      if (_isShowingFavorites) {
                        context.read<MovieListBloc>().add(LoadFavoriteMovies());
                      } else {
                        context.read<MovieListBloc>().add(LoadTrendingMovies());
                      }
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
      ),
    );
  }

  Widget _buildMovieList() {
    return BlocBuilder<MovieListBloc, MovieListState>(
      builder: (context, state) {
        if (state is MovieListInitial || state is MovieListLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MovieListLoaded) {
          final movies = state.movies;

          if (movies.isEmpty) {
            String message = 'No movies found';
            if (state.isShowingFavorites) {
              message = 'No favorite movies yet';
            } else if (state.searchQuery != null &&
                state.searchQuery!.isNotEmpty) {
              message = 'No results found for "${state.searchQuery}"';
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.isShowingFavorites
                        ? Icons.favorite_border
                        : Icons.movie_outlined,
                    size: 64,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(message, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(
                movie: movie,
                onTap: () => _navigateToDetail(movie),
              );
            },
          );
        } else if (state is MovieListError) {
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
                  'Error loading movies',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    if (_isShowingFavorites) {
                      context.read<MovieListBloc>().add(LoadFavoriteMovies());
                    } else {
                      context.read<MovieListBloc>().add(LoadTrendingMovies());
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        // Default fallback
        return const Center(child: Text('Something went wrong'));
      },
    );
  }

  Widget _buildFavoritesToggle() {
    return BlocBuilder<MovieListBloc, MovieListState>(
      builder: (context, state) {
        final isShowingFavorites =
            state is MovieListLoaded
                ? state.isShowingFavorites
                : _isShowingFavorites;

        return IconButton(
          icon: Icon(
            isShowingFavorites ? Icons.favorite : Icons.favorite_border,
            color: isShowingFavorites ? Colors.red : Colors.white,
          ),
          onPressed: () {
            setState(() {
              _isShowingFavorites = !_isShowingFavorites;
            });

            // Clear search when toggling
            if (_searchController.text.isNotEmpty) {
              _searchController.clear();
            }

            if (_isShowingFavorites) {
              context.read<MovieListBloc>().add(LoadFavoriteMovies());
            } else {
              context.read<MovieListBloc>().add(LoadTrendingMovies());
            }
          },
        );
      },
    );
  }

  void _navigateToDetail(MovieModel movie) {
    // Store navigation time to detect returns
    _lastNavigatedTime = DateTime.now();

    context
        .push(
          '${AppRouter.detailRoute.replaceFirst(':id', '${movie.id}')}',
          extra: movie,
        )
        .then((returnValue) {
          // Check if data was returned from the detail screen
          if (mounted && returnValue != null) {
            print('DEBUG: Received return data: $returnValue');

            if (returnValue is Map<String, dynamic>) {
              // If we have favorite status data, update just that movie
              if (returnValue.containsKey('movieId') &&
                  returnValue.containsKey('isFavorite')) {
                final movieId = returnValue['movieId'] as int;
                final isFavorite = returnValue['isFavorite'] as bool;

                print(
                  'DEBUG: Updating movie $movieId to favorite status: $isFavorite',
                );

                // Direct update of favorite status without setState
                // to prevent entire list refresh
                context.read<MovieListBloc>().add(
                  UpdateMovieFavoriteStatus(
                    movieId: movieId,
                    isFavorite: isFavorite,
                  ),
                );
              }
            }
          }
        });
  }
}
