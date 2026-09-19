import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/entity_schema.dart';
import 'screens/dashboard_screen.dart';
import 'screens/entity_detail_screen.dart';
import 'screens/entity_form_screen.dart';
import 'screens/entity_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'state/auth_controller.dart';
import 'widgets/app_shell.dart';

GoRouter buildRouter(AuthController auth) {
  String? guardCollection(String collection) {
    final schema = entitySchemas[collection];
    if (schema == null) return '/dashboard';
    if (auth.user?.role != schema.ownerRole) return '/forbidden';
    return null;
  }

  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final path = state.uri.path;
      final public = path == '/login' || path == '/register';

      if (!auth.isAuthenticated && !public) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (auth.isAuthenticated && public) {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.startsWith('/')) return from;
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forbidden',
        builder: (context, state) => const ForbiddenScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/data/:collection',
            redirect: (context, state) => guardCollection(
              state.pathParameters['collection'] ?? '',
            ),
            builder: (context, state) => EntityListScreen(
              collection: state.pathParameters['collection']!,
              uri: state.uri,
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => EntityFormScreen(
                  collection: state.pathParameters['collection']!,
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => EntityDetailScreen(
                  collection: state.pathParameters['collection']!,
                  id: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => EntityFormScreen(
                      collection: state.pathParameters['collection']!,
                      id: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/', redirect: (context, state) => '/dashboard'),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 12),
              const Text('Страница не найдена'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
