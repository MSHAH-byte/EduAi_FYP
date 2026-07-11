import 'dart:convert';
import 'package:http/http.dart' as http;

class FastApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';

  Future<Map<String, dynamic>> generateSlides(String topic, int numSlides) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate/slides'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'topic': topic, 'num_items': numSlides}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to generate slides: ${response.body}');
  }

  Future<Map<String, dynamic>> generateNotes(String topic) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'topic': topic, 'num_items': 5}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to generate notes: ${response.body}');
  }

  Future<Map<String, dynamic>> generateQuiz(String topic, int numQuestions) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate/quiz'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'topic': topic, 'num_items': numQuestions}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to generate quiz: ${response.body}');
  }

  Future<String> chat(String message, List<Map<String, dynamic>> history) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'conversation_history': history,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['response'];
    }
    throw Exception('Failed to get chat response: ${response.body}');
  }
}
