import 'dart:async';

/// Describes a cross-screen scheduling event that other widgets can react to.
class SessionEvent {
  SessionEvent({
    required this.type,
    required this.sessionId,
    this.therapistUserId,
    this.clientUserId,
  });

  final SessionEventType type;
  final String sessionId;
  final String? therapistUserId;
  final String? clientUserId;
}

/// Supported types of session events that matter for UI refreshes.
enum SessionEventType { cancelled, slotReleased }

/// Simple broadcast bus so the client and therapist dashboards stay in sync.
class SessionEventBus {
  SessionEventBus._();

  static final SessionEventBus instance = SessionEventBus._();

  final StreamController<SessionEvent> _controller =
      StreamController<SessionEvent>.broadcast();

  Stream<SessionEvent> get stream => _controller.stream;

  void emit(SessionEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
