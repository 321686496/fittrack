import 'dart:async';

enum LiveViewAction { skipRest, resume }

class LiveViewEvent {
  final LiveViewAction action;
  final Map<String, dynamic> payload;

  LiveViewEvent({required this.action, required this.payload});
}

abstract class LiveViewService {
  Future<void> startRestLiveView({
    required String exerciseName,
    required int restSeconds,
    required DateTime restEndTime,
  });
  Future<void> stopRestLiveView();
  Stream<LiveViewEvent> get onUserAction;
}
