import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemini Text Analyzer using direct HTTP API calls
/// Uses confirmed working models: gemini-flash-latest (preferred) and gemini-pro-latest
/// API endpoint: v1beta (mandatory)
class GeminiTextAnalyzer {
  final String _apiKey;

  GeminiTextAnalyzer(String apiKey) : _apiKey = apiKey {
    if (apiKey.isEmpty) {
      throw ArgumentError('Gemini API key is missing');
    }
  }

  /// Summarizes note content using Gemini AI
  /// Returns a concise 1-2 sentence summary
  Future<String> summarizeNote(String content) async {
    if (content.trim().isEmpty) {
      return '';
    }

    // Confirmed working models in order of preference
    final modelNames = [
      'gemini-flash-latest',  // PREFERRED - confirmed working
      'gemini-pro-latest',    // Fallback - confirmed working
    ];

    final prompt = 'Summarize this note in 1-2 short sentences. Keep it concise and clear. Note content:\n$content';

    for (final modelName in modelNames) {
      try {
        debugPrint('[Gemini] Attempting model: $modelName');
        
        final result = await _callGeminiAPI(modelName, prompt);
        
        if (result != null && result.isNotEmpty) {
          debugPrint('[Gemini] Successfully generated summary using: $modelName');
          return result;
        }
      } catch (e) {
        debugPrint('[Gemini] Model $modelName failed: $e');
        // Continue to next model
      }
    }

    throw Exception('Failed to generate summary. All models failed. Check API key and network connection.');
  }

  /// Direct HTTP API call to Gemini
  /// Uses v1beta endpoint with query parameter for API key
  Future<String?> _callGeminiAPI(String modelName, String prompt) async {
    try {
      // Mandatory endpoint format: v1beta/models/{model}:generateContent
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_apiKey'
      );

      // Request body format as specified
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      };

      debugPrint('[Gemini] POST $url');
      debugPrint('[Gemini] Request body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('[Gemini] Response status: ${response.statusCode}');
      debugPrint('[Gemini] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Parse response: data["candidates"][0]["content"]["parts"][0]["text"]
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (text != null && text.toString().isNotEmpty) {
          return text.toString().trim();
        } else {
          debugPrint('[Gemini] Empty response text in valid response');
          return null;
        }
      } else {
        // Log full error details - do NOT swallow errors
        final errorMsg = 'HTTP ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          final apiError = errorData['error'];
          if (apiError != null) {
            debugPrint('[Gemini] API Error Code: ${apiError['code']}');
            debugPrint('[Gemini] API Error Message: ${apiError['message']}');
            debugPrint('[Gemini] API Error Status: ${apiError['status']}');
            throw Exception('$errorMsg - ${apiError['message']}');
          }
        } catch (e) {
          if (e is Exception && e.toString().contains('API Error')) {
            rethrow;
          }
        }
        throw Exception('$errorMsg - ${response.body}');
      }
    } catch (e) {
      debugPrint('[Gemini] Exception in API call: $e');
      rethrow;
    }
  }
}