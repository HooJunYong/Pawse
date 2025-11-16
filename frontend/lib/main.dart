import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String message = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchMessage();
  }

  Future<void> fetchMessage() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
    final url = Uri.parse("$baseUrl/");
    // Log the base URL for debugging
    print('Fetching from: $url');
    setState(() { message = 'Trying $url'; });
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          message = json.decode(response.body)['message'];
        });
      } else {
        setState(() {
          message = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        message = "Connection failed: $e\nTried: $url";
      });
      print('Fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('AI Mental Health Companion')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
