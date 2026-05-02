import 'package:flutter/material.dart';

import '../services/app_session_service.dart';

class SessionActivityListener extends StatefulWidget {
  const SessionActivityListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SessionActivityListener> createState() =>
      _SessionActivityListenerState();
}

class _SessionActivityListenerState extends State<SessionActivityListener>
    with WidgetsBindingObserver {
  final AppSessionService _sessionService = AppSessionService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _sessionService.handleLifecycleChange(state);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    _sessionService.markActivity();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _sessionService.markActivity(),
        onPointerMove: (_) => _sessionService.markActivity(),
        onPointerSignal: (_) => _sessionService.markActivity(),
        onPointerPanZoomStart: (_) => _sessionService.markActivity(),
        child: widget.child,
      ),
    );
  }
}
