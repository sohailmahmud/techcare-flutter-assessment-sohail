import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Event transformation utilities for BLoC
class EventTransformers {
  /// Debounce transformer - delays events until no new events occur for the specified duration
  static EventTransformer<T> debounce<T>(Duration duration) {
    return (events, mapper) {
      return events
          .distinct()
          .debounceTime(duration)
          .asyncExpand(mapper);
    };
  }

  /// Throttle transformer - emits first event and ignores subsequent events for the specified duration
  static EventTransformer<T> throttle<T>(Duration duration) {
    return (events, mapper) {
      return events
          .distinct()
          .throttleTime(duration)
          .asyncExpand(mapper);
    };
  }

  /// Restartable transformer - cancels previous operations when new events occur
  static EventTransformer<T> restartable<T>() {
    return (events, mapper) {
      return events.switchMap(mapper);
    };
  }

  /// Sequential transformer - processes events one by one in order
  static EventTransformer<T> sequential<T>() {
    return (events, mapper) {
      return events.asyncExpand(mapper);
    };
  }

  /// Concurrent transformer - processes events concurrently
  static EventTransformer<T> concurrent<T>() {
    return (events, mapper) {
      return events.flatMap(mapper);
    };
  }

  /// Drop new transformer - ignores new events while processing current one
  static EventTransformer<T> droppable<T>() {
    return (events, mapper) {
      return events.exhaustMap(mapper);
    };
  }
}

/// Extension methods for Stream to support transformations
extension _StreamExtensions<T> on Stream<T> {
  Stream<T> debounceTime(Duration duration) {
    Timer? debounceTimer;
    late StreamController<T> streamController;
    StreamSubscription<T>? subscription;

    streamController = StreamController<T>(
      onListen: () {
        subscription = listen(
          (data) {
            debounceTimer?.cancel();
            debounceTimer = Timer(duration, () {
              streamController.add(data);
            });
          },
          onError: streamController.addError,
          onDone: () {
            debounceTimer?.cancel();
            streamController.close();
          },
        );
      },
      onCancel: () {
        debounceTimer?.cancel();
        subscription?.cancel();
      },
    );

    return streamController.stream;
  }

  Stream<T> throttleTime(Duration duration) {
    DateTime lastEmitted = DateTime.fromMillisecondsSinceEpoch(0);
    late StreamController<T> streamController;
    StreamSubscription<T>? subscription;

    streamController = StreamController<T>(
      onListen: () {
        subscription = listen(
          (data) {
            final now = DateTime.now();
            if (now.difference(lastEmitted) >= duration) {
              lastEmitted = now;
              streamController.add(data);
            }
          },
          onError: streamController.addError,
          onDone: streamController.close,
        );
      },
      onCancel: () => subscription?.cancel(),
    );

    return streamController.stream;
  }

  Stream<S> switchMap<S>(Stream<S> Function(T) mapper) {
    late StreamController<S> streamController;
    StreamSubscription<T>? outerSubscription;
    StreamSubscription<S>? innerSubscription;

    streamController = StreamController<S>(
      onListen: () {
        outerSubscription = listen(
          (data) {
            innerSubscription?.cancel();
            innerSubscription = mapper(data).listen(
              streamController.add,
              onError: streamController.addError,
            );
          },
          onError: streamController.addError,
          onDone: streamController.close,
        );
      },
      onCancel: () {
        innerSubscription?.cancel();
        outerSubscription?.cancel();
      },
    );

    return streamController.stream;
  }

  Stream<S> flatMap<S>(Stream<S> Function(T) mapper) {
    late StreamController<S> streamController;
    StreamSubscription<T>? outerSubscription;
    final List<StreamSubscription<S>> innerSubscriptions = [];

    streamController = StreamController<S>(
      onListen: () {
        outerSubscription = listen(
          (data) {
            final innerSubscription = mapper(data).listen(
              streamController.add,
              onError: streamController.addError,
            );
            innerSubscriptions.add(innerSubscription);
          },
          onError: streamController.addError,
          onDone: () async {
            await Future.wait(innerSubscriptions.map((s) => s.cancel()));
            streamController.close();
          },
        );
      },
      onCancel: () async {
        await Future.wait([
          outerSubscription?.cancel() ?? Future.value(),
          ...innerSubscriptions.map((s) => s.cancel()),
        ]);
      },
    );

    return streamController.stream;
  }

  Stream<S> exhaustMap<S>(Stream<S> Function(T) mapper) {
    late StreamController<S> streamController;
    StreamSubscription<T>? outerSubscription;
    StreamSubscription<S>? innerSubscription;
    bool isProcessing = false;

    streamController = StreamController<S>(
      onListen: () {
        outerSubscription = listen(
          (data) {
            if (!isProcessing) {
              isProcessing = true;
              innerSubscription = mapper(data).listen(
                streamController.add,
                onError: streamController.addError,
                onDone: () => isProcessing = false,
              );
            }
          },
          onError: streamController.addError,
          onDone: streamController.close,
        );
      },
      onCancel: () {
        innerSubscription?.cancel();
        outerSubscription?.cancel();
      },
    );

    return streamController.stream;
  }
}