import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:gym_owner_web/data/models/gym_owner_models.dart';

class EventsNotifier extends Notifier<List<EventModel>> {
  @override
  List<EventModel> build() {
    fetchEvents();
    return [];
  }

  Future<void> fetchEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://localhost:5000/api/events'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        state = data.map((json) => EventModel.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> addEvent(EventModel event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': event.title,
          'date': event.date,
        }),
      );

      if (response.statusCode == 201) {
        final newEvent = EventModel.fromJson(jsonDecode(response.body));
        state = [...state, newEvent];
      } else {
        print('Failed to create event: ${response.body}');
      }
    } catch (e) {
      print('Error creating event: $e');
    }
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, List<EventModel>>(() {
  return EventsNotifier();
});
