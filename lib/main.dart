import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'features/event_detail/event_detail_screen.dart';
import 'features/feed/events_view_model.dart';
import 'features/feed/kai_home_page.dart';

void main() {
  // Hang the view model above every screen, so any widget in the app can
  // reach it without a single value being passed down by hand. Above the
  // router too, which is what makes both screens see the same stars.
  runApp(
    ChangeNotifierProvider(
      create: (_) => EventsViewModel()..load(),
      child: const KaiFinderApp(initialLocation: '/event/free-samosas'),
      // child: const KaiFinderApp(),
    ),
  );
}

// The route table: URLs mapped to screens, with the parameter in the path.
// Navigation stops being Navigator.push calls scattered through the widgets
// and becomes data, in one place you can read.
// GoRouter createRouter() => GoRouter(
GoRouter createRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const KaiHomePage(),
      // A CHILD of '/', so going to /event/free-samosas puts the detail screen
      // ON TOP of the feed. That is where the back button comes from: nobody
      // asked for one, the shape of the table produced it.
      routes: [
        GoRoute(
          path: 'event/:id',
          builder: (context, state) =>
              EventDetailScreen(id: state.pathParameters['id']!),
        ),
      ],
    ),
  ],
);

class KaiFinderApp extends StatefulWidget {
  const KaiFinderApp({super.key, this.initialLocation = '/'});

  final String initialLocation;

  @override
  State<KaiFinderApp> createState() => _KaiFinderAppState();
}

class _KaiFinderAppState extends State<KaiFinderApp> {
  // Built once and kept. A router rebuilt on every frame would forget where
  // the user is standing.
  //late final GoRouter _router = createRouter();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = createRouter(initialLocation: widget.initialLocation);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Kai Finder',
      theme: ThemeData(
        // One seed colour, and Material derives a whole palette from it.
        // For the course brand green instead, use const Color(0xFF01913A).
        colorScheme: .fromSeed(seedColor: Colors.green),
      ),
      routerConfig: _router,
    );
  }
}
