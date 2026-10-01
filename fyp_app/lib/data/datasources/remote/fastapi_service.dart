import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Thrown by summarizeDocument so the UI can show a readable message
/// instead of a raw Exception string.
class DocumentUploadException implements Exception {
  final String message;
  const DocumentUploadException(this.message);

  @override
  String toString() => message;
}

class DocumentSummary {
  final String filename;
  final String summary;
  final int characterCount;

  const DocumentSummary({
    required this.filename,
    required this.summary,
    required this.characterCount,
  });

  factory DocumentSummary.fromJson(Map<String, dynamic> json) {
    return DocumentSummary(
      filename: json['filename'] as String? ?? 'document',
      summary: json['summary'] as String? ?? '',
      characterCount: json['character_count'] as int? ?? 0,
    );
  }
}

class FastApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api/v1';

  /// A local 4B model is slow: 10 sequential calls for a long PDF is normal.
  static const Duration _uploadTimeout = Duration(minutes: 5);

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

  // -------------------------------------------------------------------
  // Document upload + summarization
  // -------------------------------------------------------------------

  /// Uploads a PDF or DOCX to /document/summarize and returns the summary.
  ///
  /// Throws [DocumentUploadException] with a user-facing message. The four
  /// methods above keep their existing throw-Exception behaviour so nothing
  /// that already calls them changes.
  Future<DocumentSummary> summarizeDocument(File file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/document/summarize'),
    )..files.add(await http.MultipartFile.fromPath('file', file.path));

    http.StreamedResponse streamed;
    try {
      streamed = await request.send().timeout(_uploadTimeout);
    } on SocketException {
      throw const DocumentUploadException(
        'Could not reach the server. Make sure FastAPI is running.',
      );
    } catch (_) {
      throw const DocumentUploadException(
        'The request timed out. The document may be too long for the model.',
      );
    }

    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      try {
        return DocumentSummary.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        );
      } catch (_) {
        throw const DocumentUploadException(
          'The server returned an unexpected response.',
        );
      }
    }

    throw DocumentUploadException(_errorMessage(streamed.statusCode, body));
  }

  String _errorMessage(int statusCode, String body) {
    // FastAPI puts readable text in `detail` for HTTPException.
    String? detail;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['detail'] is String) {
        detail = decoded['detail'] as String;
      }
    } catch (_) {
      // fall through to the generic messages below
    }

    switch (statusCode) {
      case 413:
        return detail ?? 'That file is too large (limit is 10 MB).';
      case 415:
        return detail ?? 'Only PDF and DOCX files are supported.';
      case 422:
        return detail ?? 'No readable text could be found in that document.';
      case 503:
        return detail ??
            'The AI model is unavailable. Check that Ollama is running.';
      default:
        return detail ?? 'Something went wrong (error $statusCode).';
    }
  }
}
