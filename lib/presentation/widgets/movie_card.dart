import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stage_movie/core/theme/app_theme.dart';
import 'package:stage_movie/data/models/movie_model.dart';
import 'package:stage_movie/presentation/blocs/movie_list/movie_list_bloc.dart';

class MovieCard extends StatefulWidget {
  final MovieModel movie;
  final VoidCallback onTap;

  const MovieCard({Key? key, required this.movie, required this.onTap})
    : super(key: key);

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.movie.isFavorite;
  }

  @override
  void didUpdateWidget(covariant MovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update favorite status if the movie changed
    if (oldWidget.movie.isFavorite != widget.movie.isFavorite) {
      setState(() {
        _isFavorite = widget.movie.isFavorite;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if the movie is in the current state
    final currentState = context.watch<MovieListBloc>().state;
    if (currentState is MovieListLoaded) {
      for (final stateMovie in currentState.movies) {
        if (stateMovie.id == widget.movie.id &&
            stateMovie.isFavorite != _isFavorite) {
          // Update our local state if it differs from the bloc state
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isFavorite = stateMovie.isFavorite;
                print(
                  'DEBUG: Updating card favorite status to: $_isFavorite for movie ${widget.movie.id}',
                );
              });
            }
          });
          break;
        }
      }
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Poster image
            Positioned.fill(
              child: Hero(
                tag: 'movie_poster_${widget.movie.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.movie.fullPosterPath,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: AppTheme.cardColor,
                        child: const Center(child: CircularProgressIndicator()),
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
              ),
            ),

            // Hidden backdrop hero widget for smooth transition
            Opacity(
              opacity: 0,
              child: Hero(
                tag: 'movie_backdrop_${widget.movie.id}',
                child: Container(width: 0, height: 0),
              ),
            ),

            // Title gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.movie.voteAverage.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.movie.year,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Favorite icon
            Positioned(top: 8, right: 8, child: _buildFavoriteIcon()),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteIcon() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        context.read<MovieListBloc>().add(ToggleMovieFavorite(widget.movie));
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? Colors.red : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
