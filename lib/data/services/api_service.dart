import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/kai_event.dart';

// Everything that talks to the network lives here, and nothing else does.
// The UI asks for a List<KaiEvent> and never learns what HTTP is.
class ApiService {
  // The client is injectable so tests can hand in a fake one and never
  // touch the network.
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Android emulator cannot see the host's localhost: use 10.0.2.2
  static const _base = 'http://10.0.2.2:3734'; // Chrome/desktop: localhost

  Future<List<KaiEvent>> fetchEvents() async {
    final response = await _client.get(Uri.parse('$_base/events'));
    // A server saying "no" is data, not an exception. Check the code.
    if (response.statusCode != 200) {
      throw Exception('Server said ${response.statusCode}');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => KaiEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KaiEvent> eatEvent(String id) async {
    final response = await _client.post(Uri.parse('$_base/events/$id/eat'));

    if (response.statusCode != 200) {
      throw Exception('Server said ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return KaiEvent.fromJson(json);
  }
}
