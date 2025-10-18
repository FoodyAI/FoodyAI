import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/food_analysis.dart';
import 'ai_service.dart';

class ClaudeService implements AIService {
  final String _apiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
  final String _apiUrl = 'https://api.anthropic.com/v1/messages';
  // Default model - Sonnet is strong for vision; can be adjusted
  final String _model = 'claude-3-5-sonnet-latest';

  @override
  Future<FoodAnalysis> analyzeImage(File image) async {
    try {
      final base64Image = base64Encode(await image.readAsBytes());

      final requestBody = {
        'model': _model,
        'max_tokens': 300,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Analyze this image and determine if it contains FOOD, DRINK, or FOOD INGREDIENTS (vegetables, fruits, raw materials, etc.). Respond ONLY in valid JSON format: {"isFoodRelated": boolean, "name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Set isFoodRelated to true ONLY if the image shows food, beverages, or food ingredients. Set it to false for non-food items like cars, phones, people, buildings, etc. Values should be in grams except healthScore (0-10). No code blocks, no markdown.'
              },
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': '<IMAGE_BASE64>'
                }
              }
            ]
          }
        ]
      };

      print('🤖 [Claude] Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 300,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text':
                      'Analyze this food image and respond ONLY in valid JSON: {"name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Units in grams; healthScore 0-10. No code blocks, no markdown.'
                },
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image
                  }
                }
              ]
            }
          ]
        }),
      );

      print('📥 [Claude] Response Status: ${response.statusCode}');
      print('📥 [Claude] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['content'] as List).isNotEmpty
            ? data['content'][0]['text'] as String
            : '';

        print('📝 [Claude] Extracted Content: $content');

        final jsonRegExp = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegExp.firstMatch(content);
        final jsonString = match?.group(0) ?? content;

        final jsonResponse = jsonDecode(jsonString) as Map<String, dynamic>;
        print('✅ [Claude] Parsed JSON: $jsonResponse');
        
        return FoodAnalysis(
          name: jsonResponse['name'] as String,
          protein: (jsonResponse['protein'] as num).toDouble(),
          carbs: (jsonResponse['carbs'] as num).toDouble(),
          fat: (jsonResponse['fat'] as num).toDouble(),
          calories: (jsonResponse['calories'] as num).toDouble(),
          healthScore: (jsonResponse['healthScore'] as num).toDouble(),
        );
      } else {
        throw Exception(
            'Claude API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image with Claude: $e');
    }
  }
}
