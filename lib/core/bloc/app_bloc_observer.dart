import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/logger.dart';

/// Global BLoC observer for debugging and monitoring
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    Logger.d('BLoC Created: ${bloc.runtimeType}');
  }

  @override
  void onEvent(BlocBase bloc, Object? event) {
    if (bloc is Bloc) {
      super.onEvent(bloc, event);
    }
    Logger.d('BLoC Event: ${bloc.runtimeType} - $event');
  }

  @override
  void onTransition(BlocBase bloc, Transition transition) {
    if (bloc is Bloc) {
      super.onTransition(bloc, transition);
    }
    Logger.d('BLoC Transition: ${bloc.runtimeType} - ${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    Logger.d('BLoC Change: ${bloc.runtimeType} - ${change.currentState.runtimeType} -> ${change.nextState.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    Logger.e('BLoC Error: ${bloc.runtimeType}', error: error, stackTrace: stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    Logger.d('BLoC Closed: ${bloc.runtimeType}');
  }
}