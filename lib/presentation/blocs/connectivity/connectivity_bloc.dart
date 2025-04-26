import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stage_movie/core/services/connectivity_service.dart';

part 'connectivity_event.dart';
part 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService _connectivityService;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _lastConnectionStatus = true; // Default to connected

  ConnectivityBloc(this._connectivityService) : super(ConnectivityInitial()) {
    on<CheckConnectivity>(_onCheckConnectivity);
    on<ConnectivityChanged>(_onConnectivityChanged);

    // Initialize connection status
    _initConnectivity();

    // Subscribe to connectivity changes
    _connectivitySubscription = _connectivityService.connectivityStream.listen((
      result,
    ) {
      final isConnected = result != ConnectivityResult.none;

      // Only emit if the status has changed to avoid multiple emissions
      if (isConnected != _lastConnectionStatus) {
        _lastConnectionStatus = isConnected;
        add(ConnectivityChanged(isConnected));
      }
    });
  }

  Future<void> _initConnectivity() async {
    try {
      final isConnected = await _connectivityService.isConnected();
      _lastConnectionStatus = isConnected;
      emit(ConnectivityStatus(isConnected));
    } catch (_) {
      emit(const ConnectivityStatus(false));
    }
  }

  Future<void> _onCheckConnectivity(
    CheckConnectivity event,
    Emitter<ConnectivityState> emit,
  ) async {
    emit(ConnectivityLoading());
    try {
      final isConnected = await _connectivityService.isConnected();
      _lastConnectionStatus = isConnected;
      emit(ConnectivityStatus(isConnected));
    } catch (e) {
      emit(const ConnectivityStatus(false));
    }
  }

  void _onConnectivityChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    emit(ConnectivityStatus(event.isConnected));
  }

  @override
  Future<void> close() {
    _connectivitySubscription.cancel();
    return super.close();
  }
}
