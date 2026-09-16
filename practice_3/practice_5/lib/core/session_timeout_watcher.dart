import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';
import 'auth_session.dart';

class SessionTimeoutWatcher
    extends StatefulWidget {
  final Widget child;

  const SessionTimeoutWatcher({
    super.key,
    required this.child,
  });

  @override
  State<SessionTimeoutWatcher>
      createState() =>
          _SessionTimeoutWatcherState();
}

class _SessionTimeoutWatcherState
    extends State<SessionTimeoutWatcher> {
  // Выход после 3 минут бездействия.
  static const Duration _inactivityTimeout =
      Duration(
    minutes: 3,
  );

  // Предупреждение за 30 секунд.
  static const Duration _warningBefore =
      Duration(
    seconds: 30,
  );

  // Максимальная длительность всей сессии.
  //
  // Для учебной работы ставим 5 минут,
  // чтобы проверку не пришлось ждать долго.
  static const Duration _maxSessionDuration =
      Duration(
    minutes: 5,
  );

  Timer? _warningTimer;
  Timer? _inactivityLogoutTimer;
  Timer? _absoluteLogoutTimer;

  AuthSession? _session;

  bool _warningVisible = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler(
      _onKeyEvent,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newSession =
        context.read<AuthSession>();

    if (!identical(
      _session,
      newSession,
    )) {
      _session?.removeListener(
        _onSessionChanged,
      );

      _session =
          newSession;

      _session?.addListener(
        _onSessionChanged,
      );

      _onSessionChanged();
    }
  }

  @override
  void dispose() {
    _cancelAllTimers();

    _session?.removeListener(
      _onSessionChanged,
    );

    HardwareKeyboard.instance.removeHandler(
      _onKeyEvent,
    );

    super.dispose();
  }

  void _onSessionChanged() {
    final session =
        _session;

    if (session == null ||
        !session.isAuthenticated) {
      _cancelAllTimers();
      return;
    }

    // Таймер неактивности можно начинать заново.
    _restartInactivityTimers();

    // Общий таймер рассчитывается относительно
    // сохранённого времени начала сессии.
    _scheduleAbsoluteLogout();
  }

  bool _onKeyEvent(
    KeyEvent event,
  ) {
    if (event is KeyDownEvent) {
      _registerActivity();
    }

    // false — событие продолжает обрабатываться
    // остальными виджетами.
    return false;
  }

  void _registerActivity() {
    final session =
        _session;

    if (session == null ||
        !session.isAuthenticated ||
        _loggingOut) {
      return;
    }

    _hideWarning();

    // Клики и клавиши сбрасывают ТОЛЬКО
    // таймер неактивности.
    _restartInactivityTimers();

    // _absoluteLogoutTimer здесь
    // специально не трогаем.
  }

  void _restartInactivityTimers() {
    _warningTimer?.cancel();
    _inactivityLogoutTimer?.cancel();

    final warningDelay =
        _inactivityTimeout -
            _warningBefore;

    _warningTimer =
        Timer(
      warningDelay,
      _showInactivityWarning,
    );

    _inactivityLogoutTimer =
        Timer(
      _inactivityTimeout,
      _logoutBecauseOfInactivity,
    );
  }

  void _scheduleAbsoluteLogout() {
    _absoluteLogoutTimer?.cancel();

    final session =
        _session;

    if (session == null ||
        !session.isAuthenticated) {
      return;
    }

    final startedAt =
        session.sessionStartedAt;

    if (startedAt == null) {
      return;
    }

    final elapsed =
        DateTime.now().difference(
      startedAt,
    );

    final remaining =
        _maxSessionDuration -
            elapsed;

    // Если после F5 выяснилось,
    // что максимальный срок уже закончился,
    // выходим сразу.
    if (remaining <= Duration.zero) {
      Future.microtask(
        _logoutBecauseOfMaximumDuration,
      );

      return;
    }

    _absoluteLogoutTimer =
        Timer(
      remaining,
      _logoutBecauseOfMaximumDuration,
    );
  }

  void _cancelAllTimers() {
    _warningTimer?.cancel();
    _inactivityLogoutTimer?.cancel();
    _absoluteLogoutTimer?.cancel();

    _warningTimer =
        null;

    _inactivityLogoutTimer =
        null;

    _absoluteLogoutTimer =
        null;

    _hideWarning();
  }

  void _showInactivityWarning() {
    if (!mounted) {
      return;
    }

    final session =
        _session;

    if (session == null ||
        !session.isAuthenticated) {
      return;
    }

    _warningVisible =
        true;

    final messenger =
        ScaffoldMessenger.maybeOf(
      context,
    );

    messenger?.hideCurrentSnackBar();

    messenger?.showSnackBar(
      const SnackBar(
        duration: Duration(
          seconds: 30,
        ),
        content: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              color: Colors.white,
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              child: Text(
                'Сессия завершится через 30 секунд из-за неактивности.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _hideWarning() {
    if (!_warningVisible) {
      return;
    }

    _warningVisible =
        false;

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.maybeOf(
      context,
    )?.hideCurrentSnackBar();
  }

  Future<void>
      _logoutBecauseOfInactivity() async {
    await _finishSession(
      message:
          'Сессия завершена из-за неактивности.',
    );
  }

  Future<void>
      _logoutBecauseOfMaximumDuration() async {
    await _finishSession(
      message:
          'Максимальное время сессии истекло. Выполните вход снова.',
    );
  }

  Future<void> _finishSession({
    required String message,
  }) async {
    final session =
        _session;

    if (session == null ||
        !session.isAuthenticated ||
        _loggingOut) {
      return;
    }

    _loggingOut =
        true;

    _warningTimer?.cancel();
    _inactivityLogoutTimer?.cancel();
    _absoluteLogoutTimer?.cancel();

    final messenger =
        ScaffoldMessenger.maybeOf(
      context,
    );

    try {
      await context
          .read<AuthService>()
          .clearSession();

      if (!mounted) {
        return;
      }

      messenger?.hideCurrentSnackBar();

      messenger?.showSnackBar(
        SnackBar(
          duration: const Duration(
            seconds: 6,
          ),
          content: Text(
            message,
          ),
        ),
      );
    } finally {
      _loggingOut =
          false;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Listener(
      behavior:
          HitTestBehavior.translucent,

      onPointerDown: (_) {
        _registerActivity();
      },

      onPointerSignal: (_) {
        _registerActivity();
      },

      child:
          widget.child,
    );
  }
}