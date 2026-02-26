import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/landing_screen.dart';
import '../presentation/setup_screen.dart';
import '../presentation/dashboard_screen.dart';
import '../presentation/medications_screen.dart';
import '../presentation/join_team_screen.dart';
import '../presentation/observations_screen.dart';
import '../presentation/calendar_screen.dart';
import '../presentation/symptom_events_screen.dart';
import '../presentation/moments_screen.dart';
import '../presentation/care_plan_screen.dart';
import '../presentation/what_we_provide_screen.dart';
import '../presentation/how_it_works_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) =>
          const LandingScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (BuildContext context, GoRouterState state) =>
          const SetupInfoScreen(),
    ),
    GoRoute(
      path: '/join',
      builder: (BuildContext context, GoRouterState state) =>
          const JoinTeamScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (BuildContext context, GoRouterState state) =>
          const DashboardScreen(),
    ),
    GoRoute(
      path: '/medications',
      builder: (BuildContext context, GoRouterState state) =>
          const MedicationsScreen(),
    ),
    GoRoute(
      path: '/observations',
      builder: (BuildContext context, GoRouterState state) =>
          const ObservationsScreen(),
    ),
    GoRoute(
      path: '/calendar',
      builder: (BuildContext context, GoRouterState state) =>
          const CalendarScreen(),
    ),
    GoRoute(
      path: '/symptoms',
      builder: (BuildContext context, GoRouterState state) =>
          const SymptomEventsScreen(),
    ),
    GoRoute(
      path: '/moments',
      builder: (BuildContext context, GoRouterState state) =>
          const MomentsScreen(),
    ),
    GoRoute(
      path: '/care_plan',
      builder: (BuildContext context, GoRouterState state) =>
          const CarePlanScreen(),
    ),
    GoRoute(
      path: '/what_we_provide',
      builder: (BuildContext context, GoRouterState state) =>
          const WhatWeProvideScreen(),
    ),
    GoRoute(
      path: '/how_it_works',
      builder: (BuildContext context, GoRouterState state) =>
          const HowItWorksScreen(),
    ),
  ],
);
