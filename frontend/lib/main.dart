import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/homepage.dart';

Future<void> main() async {
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
        message = "Connection failed: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: Scaffold(
      //   appBar: AppBar(title: const Text('AI Mental Health Companion')),
      //   body: Center(child: Text(message)),
      // ),
      home: const HomeScreen(),
    );
  }
}
