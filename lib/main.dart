import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stage_movie/core/config/app_router.dart';
import 'package:stage_movie/core/services/connectivity_service.dart';
import 'package:stage_movie/core/services/network_service.dart';
import 'package:stage_movie/core/theme/app_theme.dart';
import 'package:stage_movie/data/datasources/local_movie_datasource.dart';
import 'package:stage_movie/data/datasources/remote_movie_datasource.dart';
import 'package:stage_movie/data/repositories/movie_repository.dart';
import 'package:stage_movie/domain/usecases/get_movie_details_usecase.dart';
import 'package:stage_movie/domain/usecases/get_movies_usecase.dart';
import 'package:stage_movie/domain/usecases/toggle_favorite_usecase.dart';
import 'package:stage_movie/presentation/blocs/connectivity/connectivity_bloc.dart';
import 'package:stage_movie/presentation/blocs/movie_list/movie_list_bloc.dart';

class AppDependencies extends InheritedWidget {
  final GetMovieDetailsUseCase getMovieDetailsUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;

  const AppDependencies({
    Key? key,
    required this.getMovieDetailsUseCase,
    required this.toggleFavoriteUseCase,
    required Widget child,
  }) : super(key: key, child: child);

  static AppDependencies of(BuildContext context, {bool listen = true}) {
    if (listen) {
      final AppDependencies? result =
          context.dependOnInheritedWidgetOfExactType<AppDependencies>();
      assert(result != null, 'No AppDependencies found in context');
      return result!;
    } else {
      final AppDependencies? result =
          context.getInheritedWidgetOfExactType<AppDependencies>();
      assert(result != null, 'No AppDependencies found in context');
      return result!;
    }
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) {
    return getMovieDetailsUseCase != oldWidget.getMovieDetailsUseCase ||
        toggleFavoriteUseCase != oldWidget.toggleFavoriteUseCase;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final connectivityService = ConnectivityService();
  final networkService = NetworkService();
  final localMovieDataSource = LocalMovieDataSource();

  await localMovieDataSource.initialize();

  final remoteMovieDataSource = RemoteMovieDataSource(networkService);
  final movieRepository = MovieRepository(
    remoteMovieDataSource,
    localMovieDataSource,
    connectivityService,
  );

  final getMoviesUseCase = GetMoviesUseCase(movieRepository);
  final getMovieDetailsUseCase = GetMovieDetailsUseCase(movieRepository);
  final toggleFavoriteUseCase = ToggleFavoriteUseCase(movieRepository);

  runApp(
    StageMovieApp(
      connectivityService: connectivityService,
      getMoviesUseCase: getMoviesUseCase,
      getMovieDetailsUseCase: getMovieDetailsUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
    ),
  );
}

class StageMovieApp extends StatelessWidget {
  final ConnectivityService connectivityService;
  final GetMoviesUseCase getMoviesUseCase;
  final GetMovieDetailsUseCase getMovieDetailsUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;

  const StageMovieApp({
    Key? key,
    required this.connectivityService,
    required this.getMoviesUseCase,
    required this.getMovieDetailsUseCase,
    required this.toggleFavoriteUseCase,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      getMovieDetailsUseCase: getMovieDetailsUseCase,
      toggleFavoriteUseCase: toggleFavoriteUseCase,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityBloc>(
            create: (context) => ConnectivityBloc(connectivityService),
          ),
          BlocProvider<MovieListBloc>(
            create:
                (context) =>
                    MovieListBloc(getMoviesUseCase, toggleFavoriteUseCase),
          ),
        ],
        child: MaterialApp.router(
          title: 'Stage Movie',
          theme: AppTheme.darkTheme,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
