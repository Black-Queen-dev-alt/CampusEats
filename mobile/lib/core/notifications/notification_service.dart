import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/core/notifications/device_repository.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

/// Notifications push (FCM) :
/// - après connexion : demande la permission, envoie le token à l'API ;
/// - au toucher d'une notification : ouvre la commande (lien direct).
///
/// Si Firebase n'est pas configuré (pas de google-services.json), le service
/// se désactive tout seul et l'app fonctionne normalement.
class NotificationService {
  NotificationService(this._devices);

  final DeviceRepository _devices;

  GoRouter? _router;
  AuthBloc? _authBloc;
  String? _pendingRoute;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  Future<void> init({
    required GoRouter router,
    required AuthBloc authBloc,
  }) async {
    _router = router;
    _authBloc = authBloc;

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Notifications désactivées (Firebase non configuré) : $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    // Notification touchée alors que l'app tournait en arrière-plan.
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTapped),
    );
    // Notification touchée alors que l'app était fermée.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _onNotificationTapped(initial);

    // Token rafraîchi par Firebase : on le renvoie à l'API.
    _subscriptions.add(messaging.onTokenRefresh.listen(_devices.registerToken));

    // Dès que l'utilisateur est connecté : permission + token + route en attente.
    _subscriptions.add(authBloc.stream.listen(_onAuthState));
    _onAuthState(authBloc.state);
  }

  Future<void> _onAuthState(AuthState state) async {
    if (state is! Authenticated) return;

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await messaging.getToken();
      if (token != null) await _devices.registerToken(token);
    }

    final pending = _pendingRoute;
    if (pending != null) {
      _pendingRoute = null;
      _router?.go(pending);
    }
  }

  void _onNotificationTapped(RemoteMessage message) {
    // L'API doit envoyer data: { orderId } avec la notification.
    final orderId = message.data['orderId'];
    if (orderId is! String || orderId.isEmpty) return;

    final route = '/orders/$orderId';
    if (_authBloc?.state is Authenticated) {
      _router?.go(route);
    } else {
      _pendingRoute = route; // ouverte dès que la session est restaurée
    }
  }

  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }
}
