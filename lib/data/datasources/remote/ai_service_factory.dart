import '../../../domain/entities/ai_provider.dart';
import 'ai_service.dart';
import 'openai_service.dart';
import 'gemini_service.dart';
import 'claude_service.dart';
import 'huggingface_service.dart';

/// Factory to create the appropriate AI service based on the selected provider
class AIServiceFactory {
  static AIService getService(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return OpenAIService();
      case AIProvider.gemini:
        return GeminiService();
      case AIProvider.claude:
        return ClaudeService();
      case AIProvider.huggingface:
        return HuggingFaceService();
    }
  }
}
