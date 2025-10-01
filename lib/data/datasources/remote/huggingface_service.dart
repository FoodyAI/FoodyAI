import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/food_analysis.dart';
import 'ai_service.dart';

/// Minimal Hugging Face inference client using a VLM (e.g., LLaVA) endpoint.
/// Note: Free tier is limited; responses may vary by model. Prompt enforces JSON.
class HuggingFaceService implements AIService {
  final String _apiKey = dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
  // Example public model; replace with a more reliable VLM endpoint if needed.
  // Some endpoints accept raw base64 image with prompt; formats vary by model.
  final String _model = 'liuhaotian/llava-v1.5-7b';

  @override
  Future<FoodAnalysis> analyzeImage(File image) async {
    try {
      final uri =
          Uri.parse('https://api-inference.huggingface.co/models/$_model');
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = 'Analyze this food image and respond ONLY as valid JSON: '
          '{"name": "food name", "protein": number, "carbs": number, '
          '"fat": number, "calories": number, "healthScore": number}. '
          'Units in grams; healthScore 0-10. No extra text.';

      final requestBody = {
        'inputs': {
          'prompt': prompt,
          'image': '<IMAGE_BASE64>',
        }
      };

      print('🤖 [HuggingFace] Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': {
            'prompt': prompt,
            'image': base64Image,
          }
        }),
      );

      print('📥 [HuggingFace] Response Status: ${response.statusCode}');
      print('📥 [HuggingFace] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // HF responses vary; attempt to extract text content robustly
        String content;
        if (body is List &&
            body.isNotEmpty &&
            body[0] is Map &&
            body[0]['generated_text'] != null) {
          content = body[0]['generated_text'] as String;
        } else if (body is Map && body['generated_text'] != null) {
          content = body['generated_text'] as String;
        } else if (body is Map && body['data'] != null) {
          content = body['data'].toString();
        } else {
          content = response.body.toString();
        }

        print('📝 [HuggingFace] Extracted Content: $content');

        final jsonRegExp = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegExp.firstMatch(content);
        final jsonString = match?.group(0) ?? content;
        final jsonResponse = jsonDecode(jsonString) as Map<String, dynamic>;

        print('✅ [HuggingFace] Parsed JSON: $jsonResponse');

        return FoodAnalysis(
          name: (jsonResponse['name'] ?? '').toString(),
          protein: (jsonResponse['protein'] as num).toDouble(),
          carbs: (jsonResponse['carbs'] as num).toDouble(),
          fat: (jsonResponse['fat'] as num).toDouble(),
          calories: (jsonResponse['calories'] as num).toDouble(),
          healthScore: (jsonResponse['healthScore'] as num).toDouble(),
        );
      } else {
        throw Exception(
            'Hugging Face API error: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing image with Hugging Face: $e');
    }
  }
}
