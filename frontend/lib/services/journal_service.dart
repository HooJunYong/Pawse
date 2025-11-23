import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/journal_model.dart';

class JournalService {
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  Future<JournalPrompt> getDailyPrompt() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/journal/prompt'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return JournalPrompt.fromJson(data);
      } else {
        throw Exception('Failed to load prompt');
      }
    } catch (e) {
      throw Exception('Error getting prompt: $e');
    }
  }

  Future<JournalEntry> createEntry(String userId, CreateJournalEntry entry) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/journal/entry/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(entry.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return JournalEntry.fromJson(data);
      } else {
        throw Exception('Failed to create entry');
      }
    } catch (e) {
      throw Exception('Error creating entry: $e');
    }
  }

  Future<List<JournalEntry>> getUserEntries(String userId, {int limit = 50, int skip = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/journal/entries/$userId?limit=$limit&skip=$skip'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => JournalEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load entries');
      }
    } catch (e) {
      throw Exception('Error getting entries: $e');
    }
  }

  Future<JournalEntry> getEntry(String entryId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/journal/entry/$entryId/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return JournalEntry.fromJson(data);
      } else {
        throw Exception('Failed to load entry');
      }
    } catch (e) {
      throw Exception('Error getting entry: $e');
    }
  }

  Future<void> deleteEntry(String entryId, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/journal/entry/$entryId/$userId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete entry');
      }
    } catch (e) {
      throw Exception('Error deleting entry: $e');
    }
  }

  Future<JournalEntry> updateEntry(String entryId, String userId, CreateJournalEntry entry) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/journal/entry/$entryId/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(entry.toJson()),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return JournalEntry.fromJson(data);
      } else {
        throw Exception('Failed to update entry');
      }
    } catch (e) {
      throw Exception('Error updating entry: $e');
    }
  }
}
