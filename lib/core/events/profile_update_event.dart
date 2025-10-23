import 'dart:async';

class ProfileUpdateEvent {
  static final StreamController<void> _controller =
      StreamController<void>.broadcast();

  static Stream<void> get stream => _controller.stream;

  static void notifyUpdate() {
    _controller.add(null);
  }

  static void dispose() {
    _controller.close();
  }
}
