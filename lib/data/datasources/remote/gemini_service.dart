import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/food_analysis.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';

  @override
  Future<FoodAnalysis> analyzeImage(File image) async {
    try {
      final base64Image = base64Encode(await image.readAsBytes());

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text':
                    'Analyze this food image and respond ONLY in valid JSON format: {"name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Values should be in grams except healthScore (0-10). Do not include any markdown formatting or code blocks, just pure JSON.'
              },
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': '<IMAGE_BASE64>',
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 256,
        }
      };

      print('🤖 [Gemini] Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Analyze this food image and respond ONLY in valid JSON format: {"name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Values should be in grams except healthScore (0-10). Do not include any markdown formatting or code blocks, just pure JSON.'
                },
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'maxOutputTokens': 256,
          }
        }),
      );

      print('📥 [Gemini] Response Status: ${response.statusCode}');
      print('📥 [Gemini] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];

        print('📝 [Gemini] Extracted Content: $content');

        // Extract JSON from response
        final jsonRegExp = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegExp.firstMatch(content);
        final jsonString = match?.group(0) ?? content;

        final jsonResponse = jsonDecode(jsonString);
        print('✅ [Gemini] Parsed JSON: $jsonResponse');
        
        return FoodAnalysis(
          name: jsonResponse['name'],
          protein: (jsonResponse['protein'] as num).toDouble(),
          carbs: (jsonResponse['carbs'] as num).toDouble(),
          fat: (jsonResponse['fat'] as num).toDouble(),
          calories: (jsonResponse['calories'] as num).toDouble(),
          healthScore: (jsonResponse['healthScore'] as num).toDouble(),
        );
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image with Gemini: $e');
    }
  }
}
