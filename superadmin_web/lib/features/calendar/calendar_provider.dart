import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final Color color;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.color,
  });
}

class CalendarNotifier extends Notifier<List<CalendarEvent>> {
  @override
  List<CalendarEvent> build() {
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
        final events = data.map((json) {
          return CalendarEvent(
            id: json['_id'],
            title: json['title'],
            description: json['description'] ?? '',
            date: DateTime.parse(json['date']),
            color: _parseColor(json['color']),
          );
        }).toList();
        
        events.sort((a, b) => a.date.compareTo(b.date));
        state = events;
      }
    } catch (e) {
      print('Error fetching calendar events: $e');
    }
  }

  Color _parseColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
  }

  Future<void> addEvent(CalendarEvent event) async {
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
          'description': event.description,
          'date': event.date.toIso8601String(),
          'color': _colorToHex(event.color),
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final newEvent = CalendarEvent(
          id: json['_id'],
          title: json['title'],
          description: json['description'] ?? '',
          date: DateTime.parse(json['date']),
          color: _parseColor(json['color']),
        );
        final newState = [...state, newEvent];
        newState.sort((a, b) => a.date.compareTo(b.date));
        state = newState;
      }
    } catch (e) {
      print('Error adding calendar event: $e');
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/events/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        state = state.where((e) => e.id != id).toList();
      }
    } catch (e) {
      print('Error deleting calendar event: $e');
    }
  }
}

final calendarProvider = NotifierProvider<CalendarNotifier, List<CalendarEvent>>(() {
  return CalendarNotifier();
});
