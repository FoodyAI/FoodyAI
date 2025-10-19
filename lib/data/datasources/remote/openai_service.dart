import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/food_analysis.dart';
import 'ai_service.dart';

class OpenAIService implements AIService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  @override
  Future<FoodAnalysis> analyzeImage(File image) async {
    try {
      final base64Image = base64Encode(await image.readAsBytes());

      final requestBody = {
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Analyze this image and determine if it contains FOOD, DRINK, or FOOD INGREDIENTS (vegetables, fruits, raw materials, etc.). Respond ONLY in valid JSON format: {"isFoodRelated": boolean, "name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Set isFoodRelated to true ONLY if the image shows food, beverages, or food ingredients. Set it to false for non-food items like cars, phones, people, buildings, etc. Values should be in grams except healthScore (0-10).'
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,<IMAGE_BASE64>'}
              }
            ]
          }
        ],
        'max_tokens': 300
      };

      print('🤖 [OpenAI] Request: ${jsonEncode(requestBody)}');

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
                      'Analyze this image and determine if it contains FOOD, DRINK, or FOOD INGREDIENTS (vegetables, fruits, raw materials, etc.). Respond ONLY in valid JSON format: {"isFoodRelated": boolean, "name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Set isFoodRelated to true ONLY if the image shows food, beverages, or food ingredients. Set it to false for non-food items like cars, phones, people, buildings, etc. Values should be in grams except healthScore (0-10).'
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

      print('📥 [OpenAI] Response Status: ${response.statusCode}');
      print('📥 [OpenAI] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        print('📝 [OpenAI] Extracted Content: $content');

        // Parse the text response into a FoodAnalysis object
        try {
          // Try to extract JSON from code block or text
          final jsonRegExp = RegExp(r'\{[\s\S]*\}');
          final match = jsonRegExp.firstMatch(content);
          final jsonString = match != null ? match.group(0) : content;

          final jsonResponse = jsonDecode(jsonString!);
          print('✅ [OpenAI] Parsed JSON: $jsonResponse');

          // Check if the image is food-related
          final isFoodRelated = jsonResponse['isFoodRelated'];
          print('🔍 [OpenAI] isFoodRelated: $isFoodRelated');
          if (isFoodRelated == false || isFoodRelated == 'false') {
            print('❌ [OpenAI] Not a food item detected!');
            throw Exception('This image is not related to food');
          }

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
