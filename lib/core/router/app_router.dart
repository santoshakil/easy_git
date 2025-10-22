import 'package:go_router/go_router.dart';
import '../../features/repositories/presentation/screens/repositories_screen_new.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'repositories',
      builder: (context, state) => const RepositoriesScreenNew(),
    ),
  ],
);
