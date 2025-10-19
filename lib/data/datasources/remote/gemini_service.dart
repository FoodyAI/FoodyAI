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
                    'Analyze this image and determine if it contains FOOD, DRINK, or FOOD INGREDIENTS (vegetables, fruits, raw materials, etc.). Respond ONLY in valid JSON format: {"isFoodRelated": boolean, "name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Set isFoodRelated to true ONLY if the image shows food, beverages, or food ingredients. Set it to false for non-food items like cars, phones, people, buildings, etc. Values should be in grams except healthScore (0-10). Do not include any markdown formatting or code blocks, just pure JSON.'
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
                      'Analyze this image and determine if it contains FOOD, DRINK, or FOOD INGREDIENTS (vegetables, fruits, raw materials, etc.). Respond ONLY in valid JSON format: {"isFoodRelated": boolean, "name": "food name", "protein": number, "carbs": number, "fat": number, "calories": number, "healthScore": number}. Set isFoodRelated to true ONLY if the image shows food, beverages, or food ingredients. Set it to false for non-food items like cars, phones, people, buildings, etc. Values should be in grams except healthScore (0-10). Do not include any markdown formatting or code blocks, just pure JSON.'
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

        // Gemini can return multiple shapes. Try to safely extract text.
        String? contentText;
        try {
          final candidates = (data['candidates'] as List?) ?? const [];
          if (candidates.isNotEmpty) {
            final first = candidates.first;
            // Newer shape: candidates[0].content.parts[0].text
            final parts =
                (((first as Map?)?['content'] as Map?)?['parts'] as List?) ??
                    const [];
            if (parts.isNotEmpty) {
              contentText = (parts.first as Map?)?['text'] as String?;
            }
            // Older/alt shape: candidates[0].content[0].text
            if (contentText == null) {
              final altParts = ((first?['content'] as List?) ?? const []);
              if (altParts.isNotEmpty) {
                contentText = (altParts.first as Map?)?['text'] as String?;
              }
            }
          }
        } catch (_) {
          // fall through to parse from entire body
        }

        // Fallback: some models may return JSON directly in a field like candidates[0].content[0].text
        contentText ??= response.body;

        print('📝 [Gemini] Extracted Content: $contentText');

        // Extract JSON from the content safely
        final jsonRegExp = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegExp.firstMatch(contentText);
        final jsonString = match?.group(0) ?? contentText;

        final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
        print('✅ [Gemini] Parsed JSON: $jsonResponse');

        // Check if the image is food-related
        final isFoodRelated = jsonResponse['isFoodRelated'];
        print('🔍 [Gemini] isFoodRelated: $isFoodRelated');
        if (isFoodRelated == false || isFoodRelated == 'false') {
          print('❌ [Gemini] Not a food item detected!');
          throw Exception('This image is not related to food');
        }

        double numToDouble(dynamic v, {double fallback = 0}) {
          if (v is num) return v.toDouble();
          if (v is String) {
            final parsed = double.tryParse(v);
            if (parsed != null) return parsed;
          }
          return fallback;
        }

        return FoodAnalysis(
          name: (jsonResponse['name'] ?? 'Unknown') as String,
          protein: numToDouble(jsonResponse['protein']),
          carbs: numToDouble(jsonResponse['carbs']),
          fat: numToDouble(jsonResponse['fat']),
          calories: numToDouble(jsonResponse['calories']),
          healthScore: numToDouble(jsonResponse['healthScore']),
        );
      } else {
        throw Exception('Failed to analyze image: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image with Gemini: $e');
    }
  }
}
