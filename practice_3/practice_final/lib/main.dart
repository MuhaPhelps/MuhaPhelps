import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'repositories/auth_repository.dart';
import 'repositories/entity_repository.dart';
import 'repositories/pocketbase_repository.dart';
import 'router.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final preferences = await SharedPreferences.getInstance();
  final auth = AuthController(
    preferences: preferences,
    repository: AuthRepository(),
  );
  await auth.restore();

  final api = ApiClient(tokenProvider: () => auth.token);
  final entityRepository = PocketBaseRepository(api);
  final router = buildRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: auth),
        Provider<EntityRepository>.value(value: entityRepository),
      ],
      child: EngineeringApp(router: router),
    ),
  );
}

class EngineeringApp extends StatelessWidget {
  final GoRouter router;

  const EngineeringApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CAE Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF365B7C)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
        ),
      ),
      routerConfig: router,
    );
  }
}
