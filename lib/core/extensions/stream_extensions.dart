import 'dart:async';

extension StreamExtensions<T> on Stream<T> {
  /// Adds a timeout to a stream to prevent it from hanging indefinitely.
  /// If no data is received within [duration], emits an error.
  Stream<T> withTimeout(Duration duration) {
    return timeout(
      duration,
      onTimeout: (sink) {
        sink.addError(
          TimeoutException(
            'Stream timeout: No data received within ${duration.inSeconds}s',
            duration,
          ),
        );
      },
    );
  }

  /// Handles empty collections by returning an empty list after a short delay.
  /// This helps distinguish between "loading" and "no data".
  Stream<List<T>> asListWithEmptyFallback(Duration waitDuration) {
    if (this is! Stream<List<T>>) {
      throw StateError('This extension only works with Stream<List<T>>');
    }

    return (this as Stream<List<T>>).transform(
      StreamTransformer<List<T>, List<T>>.fromHandlers(
        handleData: (data, sink) {
          if (data.isEmpty) {
            // Emit empty list after waiting a bit to show it's truly empty
            Future.delayed(waitDuration, () {
              sink.add(data);
            });
          } else {
            sink.add(data);
          }
        },
        handleError: (error, stackTrace, sink) {
          sink.addError(error, stackTrace);
        },
      ),
    );
  }
}
