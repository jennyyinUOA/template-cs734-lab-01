import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'portions_pill.dart';

import '../../data/models/kai_event.dart';
import 'events_view_model.dart';
import 'eat_button.dart';

// No memory of its own, so it is a StatelessWidget. Stateful is a choice.
class KaiHomePage extends StatelessWidget {
  const KaiHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Kai Finder'),
        // A second widget watching the same source of truth, on the far side
        // of the widget tree from the stars.
        actions: [
          // Upgrade four: where am I, and what is nearest. One plugin call
          // and one line of maths.
          IconButton(
            icon: const Icon(Icons.near_me),
            tooltip: 'Sort by distance',
            onPressed: () async {
              // Grab both of these BEFORE the await. After it, this context
              // may be gone, and Flutter will tell you so.
              final vm = context.read<EventsViewModel>();
              final messenger = ScaffoldMessenger.of(context);
              await vm.sortByDistance();
              if (vm.distances == null) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Location declined - feed stays unsorted'),
                  ),
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Chip(
                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                label: Text(
                  context.watch<EventsViewModel>().favouriteCount.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
      // Loading, error, data. Every screen that fetches owes you all three.
      body: const EventsFeed(),
    );
  }
}

class EventsFeed extends StatelessWidget {
  const EventsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventsViewModel>();
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return ErrorView(
        message: vm.error!,
        onRetry: () => context.read<EventsViewModel>().load(),
      );
    }
    // Data in, widgets out: one card per event, in a scrolling list.
    // Pull down to fetch again and watch the portions fall between fetches.
    return RefreshIndicator(
      onRefresh: () => context.read<EventsViewModel>().load(),
      child: ListView(
        // Without this a short list refuses to scroll, and a list that
        // cannot scroll cannot be pulled.
        physics: const AlwaysScrollableScrollPhysics(),
        children: vm.events.map((e) => KaiEventCard(event: e)).toList(),
      ),
    );
  }
}

// The state everyone forgets. A dead end with no way out is a bug report.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

// Metres up to a kilometre, then kilometres. "1400 m away" is technically
// true and nobody thinks in it.
String formatDistance(double metres) => metres < 1000
    ? '~${metres.round()} m'
    : '~${(metres / 1000).toStringAsFixed(1)} km';

// Our first hand-written widget. Stateless: it is a pure function of its inputs.
class KaiEventCard extends StatelessWidget {
  const KaiEventCard({super.key, required this.event});

  final KaiEvent event;

  @override
  Widget build(BuildContext context) {
    // Null until the near_me button has been pressed and allowed.
    final metres = context.watch<EventsViewModel>().distances?[event.id];
    final howFar = metres == null ? '' : '  -  ${formatDistance(metres)}';

    return Card(
      clipBehavior: Clip.antiAlias, // so the ripple stops at the rounded corner
      // The whole card is the tap target. The tap goes on the card rather than
      // the ListTile because later on a sold-out tile gets disabled, and a
      // disabled ListTile swallows taps. "Where was that pizza" is still a
      // fair question after the food has gone.
      child: InkWell(
        // The card does not build the next screen, or know what it is. It says
        // where to go, and the router does the rest.
        onTap: () => context.go('/event/${event.id}'),
        child: ListTile(
          // Greyed out once the food is gone, without leaving the list.
          enabled: event.isActive,
          leading: CircleAvatar(child: Text(event.emoji)),
          title: Text(
            event.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          //subtitle: Text(
          // '${event.location}  -  ${event.portionsLeft} left$howFar',
          // ),
          subtitle: Row(
            children: [
              Expanded(child: Text('${event.location}$howFar')),
              const SizedBox(width: 8),
              PortionsPill(event: event),
            ],
          ),
          //trailing: FavouriteButton(event: event),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EatButton(event: event),
              FavouriteButton(event: event),
            ],
          ),
        ),
      ),
    );
  }
}

// Yesterday this was our first StatefulWidget. It kept a bool of its own, and
// that bool was the problem: nothing else in the app could see it. Now the
// answer lives in the view model and this widget is stateless again.
//   watch = rebuild me when it changes
//   read  = just call the method
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({super.key, required this.event});

  final KaiEvent event;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EventsViewModel>();
    final isFav = vm.isFavourite(event.id);
    return IconButton(
      icon: Icon(isFav ? Icons.star : Icons.star_border),
      color: isFav ? Colors.amber : null,
      tooltip: 'Favourite',
      onPressed: () =>
          context.read<EventsViewModel>().toggleFavourite(event.id),
    );
  }
}
