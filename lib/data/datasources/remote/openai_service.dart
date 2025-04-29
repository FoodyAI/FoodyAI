import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/food_analysis.dart';

class OpenAIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<FoodAnalysis> analyzeImage(File image) async {
    try {
      final base64Image = base64Encode(await image.readAsBytes());

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Analyze this food image and respond ONLY in the following JSON format: {"name": "...", "protein": ..., "carbs": ..., "fat": ..., "calories": ..., healthScore}.'
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
          'max_tokens': 300
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Parse the text response into a FoodAnalysis object
        try {
          // Try to extract JSON from code block or text
          final jsonRegExp = RegExp(r'\{[\s\S]*\}');
          final match = jsonRegExp.firstMatch(content);
          final jsonString = match != null ? match.group(0) : content;

          final jsonResponse = jsonDecode(jsonString!);
          return FoodAnalysis(
            name: jsonResponse['name'],
            protein: jsonResponse['protein'].toDouble(),
            carbs: jsonResponse['carbs'].toDouble(),
            fat: jsonResponse['fat'].toDouble(),
            calories: jsonResponse['calories'].toDouble(),
            healthScore: jsonResponse['healthScore'].toDouble(),
          );
        } catch (e) {
          throw Exception(
              'Failed to parse JSON response: $e\nResponse content: $content');
        }
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image: $e');
    }
  }
}
