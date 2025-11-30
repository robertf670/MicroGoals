import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/widgets/main_scaffold.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/goal/add_goal/add_goal_screen.dart';
import '../../presentation/screens/goal/edit_goal/edit_goal_screen.dart';
import '../../presentation/screens/goal/detail/goal_detail_screen.dart';
import '../../presentation/screens/history/history_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/premium/premium_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/add-goal',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AddGoalScreen(),
    ),
    GoRoute(
      path: '/edit-goal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EditGoalScreen(goalId: id);
      },
    ),
    GoRoute(
      path: '/goal/:id',
      parentNavigatorKey: _rootNavigatorKey,
      name: 'goal-detail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return GoalDetailScreen(goalId: id);
      },
    ),
    GoRoute(
      path: '/premium',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PremiumScreen(),
    ),
  ],
);

