import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/app/router/app_router.dart';
import 'package:campus_eats_mobile/core/notifications/notification_service.dart';
import 'package:campus_eats_mobile/core/theme/app_theme.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. On construit toutes les dépendances AVANT de lancer l'app.
  setupDependencies();
  runApp(const CampusEatsApp());
}

class CampusEatsApp extends StatefulWidget {
  const CampusEatsApp({super.key});

  @override
  State<CampusEatsApp> createState() => _CampusEatsAppState();
}

class _CampusEatsAppState extends State<CampusEatsApp> {
  // 2. Un seul AuthBloc pour toute l'app : l'UI et le router lisent le même.
  late final AuthBloc _authBloc = getIt<AuthBloc>()..add(const AppStarted());
  late final GoRouter _router = AppRouter.create(_authBloc);

  @override
  void initState() {
    super.initState();
    // Notifications push : sans effet si Firebase n'est pas configuré.
    unawaited(
      getIt<NotificationService>().init(router: _router, authBloc: _authBloc),
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. BlocProvider.value : le bloc est fourni à tous les écrans,
    //    sans être fermé par le provider (il appartient à get_it).
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'CampusEats',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
      ),
    );
  }
}
