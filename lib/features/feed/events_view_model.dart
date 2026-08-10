import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/kai_event.dart';
import '../../data/repositories/event_repository.dart';

// State, plus the rules for changing it. No widgets, no context.
class EventsViewModel extends ChangeNotifier {
  EventsViewModel({EventRepository? repo}) : repo = repo ?? EventRepository();

  // The view model asks the repository. It has never heard of HTTP.
  final EventRepository repo;

  // The three states every screen that fetches has to answer for.
  bool isLoading = false;
  String? error;
  List<KaiEvent> events = [];

  final Set<String> _favouriteIds = {};

  bool isFavourite(String id) => _favouriteIds.contains(id);
  int get favouriteCount => _favouriteIds.length;

  // The detail screen is handed an id out of the URL, not an event object, so
  // something has to be able to turn one into the other.
  KaiEvent byId(String id) => events.firstWhere((event) => event.id == id);

  void toggleFavourite(String id) {
    if (!_favouriteIds.remove(id)) {
      _favouriteIds.add(id);
    }
    notifyListeners(); // the entire trick
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      events = await repo.fetchEvents();
    } catch (e) {
      error = 'Could not reach the Kai server';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<KaiEvent> eat(String id) async {
    final updatedEvent = await repo.eatEvent(id);

    final index = events.indexWhere((event) => event.id == id);

    if (index != -1) {
      events[index] = updatedEvent;
      notifyListeners();
    }
    return updatedEvent;
  }

  // How far away each event is, in metres, once we have been told where the
  // phone is. Null until then, which is also what "the user said no" looks
  // like: no distances, feed in whatever order the server sent it.
  Map<String, double>? distances;

  // HAPPY PATH ONLY. The full decision tree, including the user who says no
  // forever and the only road back through the system settings screen, is
  // Thursday's lab. WHEN it is reasonable to ask is Monday's lecture.
  Future<void> sortByDistance() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // The one call that puts a dialog on screen, and it only does anything
      // because the manifest declares the permission.
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return; // demo: give up quietly. Thursday: handle properly.
    }

    // A real conversation with the operating system, over a method channel,
    // which is why it is a Future.
    final position = await Geolocator.getCurrentPosition();
    distances = {
      for (final event in events)
        event.id: Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          event.lat,
          event.lng,
        ),
    };
    events.sort((a, b) => distances![a.id]!.compareTo(distances![b.id]!));
    notifyListeners();
  }
}
