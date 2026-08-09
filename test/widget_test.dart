// Widget tests for Kai Finder.
//
// These never touch the network. ApiService takes an http.Client, so the
// tests hand it a MockClient that answers from a string. Real parsing code,
// no server, same result every run.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:kai_finder_lab/data/repositories/event_repository.dart';
import 'package:kai_finder_lab/data/services/api_service.dart';
import 'package:kai_finder_lab/features/event_detail/event_detail_screen.dart';
import 'package:kai_finder_lab/features/feed/events_view_model.dart';
import 'package:kai_finder_lab/features/feed/kai_home_page.dart';
import 'package:kai_finder_lab/main.dart';

// Four events, shaped exactly like the ones the Kai server returns.
final fakeEventsJson = jsonEncode([
  {
    'id': 'sausage-sizzle',
    'name': 'Sausage sizzle',
    'location': 'Engineering courtyard',
    'emoji': '🌭',
    'portionsLeft': 40,
    'isActive': true,
    'lat': -36.8527,
    'lng': 174.7666,
  },
  {
    'id': 'seminar-catering',
    'name': 'Seminar catering leftovers',
    'location': 'Science Centre 303',
    'emoji': '🥪',
    'portionsLeft': 15,
    'isActive': true,
    'lat': -36.8525,
    'lng': 174.7629,
  },
  {
    'id': 'club-barbecue',
    'name': 'Club barbecue',
    'location': 'OGGB lawn',
    'emoji': '🍖',
    'portionsLeft': 60,
    'isActive': true,
    'lat': -36.8536,
    'lng': 174.77,
  },
  {
    'id': 'free-samosas',
    'name': 'Free samosas',
    'location': 'City Campus quad',
    'emoji': '🥟',
    'portionsLeft': 0,
    'isActive': false,
    'lat': -36.8517,
    'lng': 174.7687,
  },
]);

// The app under test, wired up the same way main() wires it, but with a
// client that answers however this particular test needs it to.
Widget buildApp(MockClient client) => ChangeNotifierProvider(
  create: (_) => EventsViewModel(
    repo: EventRepository(api: ApiService(client: client)),
  )..load(),
  child: const KaiFinderApp(),
);

MockClient respondingWith(String body, {int status = 200}) => MockClient(
  (_) async => http.Response(
    body,
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  ),
);

// The count shown in the app bar chip.
Finder badge(String count) =>
    find.descendant(of: find.byType(Chip), matching: find.text(count));

void main() {
  // No widgets, no device, no permission: a pure function tested purely.
  test('distances read as metres under a kilometre, kilometres above', () {
    expect(formatDistance(240), '~240 m');
    expect(formatDistance(999.4), '~999 m');
    expect(formatDistance(1200), '~1.2 km');
  });

  testWidgets('shows a spinner, then the feed from the server', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(respondingWith(fakeEventsJson)));

    // load() has started but not finished.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Kai Finder'), findsOneWidget);
    expect(find.byType(KaiEventCard), findsNWidgets(4));
    expect(find.text('Sausage sizzle'), findsOneWidget);

    // The live portion count is on every card.
    expect(find.text('Engineering courtyard'), findsOneWidget);
    expect(find.text('Plenty (40)'), findsOneWidget);
    // The samosas ran out, so that tile is disabled but still listed.
    final samosas = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Free samosas'),
        matching: find.byType(ListTile),
      ),
    );
    expect(samosas.enabled, isFalse);
  });

  testWidgets('pull to refresh fetches again', (WidgetTester tester) async {
    var calls = 0;
    final client = MockClient((_) async {
      calls++;
      return http.Response(
        fakeEventsJson,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await tester.pumpWidget(buildApp(client));
    await tester.pumpAndSettle();
    expect(calls, 1);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(calls, 2);
  });

  testWidgets('a sold-out card still opens: the tap is on the card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(respondingWith(fakeEventsJson)));
    await tester.pumpAndSettle();

    // The samosas are gone, so their ListTile is disabled and would swallow
    // a tap. The InkWell is above it, so "where was that pizza" still works.
    await tester.tap(find.text('Free samosas'));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('0 portions left'), findsOneWidget);
  });

  testWidgets('starring a card updates that star and the badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(respondingWith(fakeEventsJson)));
    await tester.pumpAndSettle();

    expect(badge('0'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(4));

    // Starring one card leaves the other three alone.
    await tester.tap(find.byType(FavouriteButton).first);
    await tester.pump();

    // Two widgets in opposite corners of the tree, one source of truth.
    expect(badge('1'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(3));
  });

  testWidgets('tapping a card opens its detail screen, and back returns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(respondingWith(fakeEventsJson)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(KaiEventCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailScreen), findsOneWidget);

    // The back button nobody wrote: the detail route is a child of '/', so
    // the router built a stack and Material put the arrow there for free.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(EventDetailScreen), findsNothing);
    expect(find.byType(KaiEventCard), findsNWidgets(4));
  });

  testWidgets('starring on the detail screen updates the feed and the badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp(respondingWith(fakeEventsJson)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(KaiEventCard).first);
    await tester.pumpAndSettle();

    // Third home for the same widget, and no synchronisation code anywhere.
    await tester.tap(find.byType(FavouriteButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(badge('1'), findsOneWidget);
    // One card lost its empty star, so three are left holding one.
    expect(find.byIcon(Icons.star_border), findsNWidgets(3));
  });

  testWidgets('a dead server shows the error view, and retry recovers', (
    WidgetTester tester,
  ) async {
    // First call fails, every call after it succeeds.
    var firstCall = true;
    final client = MockClient((_) async {
      if (firstCall) {
        firstCall = false;
        return http.Response('kaboom', 500);
      }
      return http.Response(
        fakeEventsJson,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EventsViewModel(
          repo: EventRepository(api: ApiService(client: client)),
        )..load(),
        child: const KaiFinderApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Could not reach the Kai server'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(KaiEventCard), findsNWidgets(4));
  });
}
