import '../../../domain/entities/ai_provider.dart';
import 'ai_service.dart';
import 'openai_service.dart';
import 'gemini_service.dart';

/// Factory to create the appropriate AI service based on the selected provider
class AIServiceFactory {
  static AIService getService(AIProvider provider) {
    switch (provider) {
      case AIProvider.openai:
        return OpenAIService();
      case AIProvider.gemini:
        return GeminiService();
      case AIProvider.claude:
        // TODO: Implement Claude service when ready
        throw UnimplementedError('Claude API is not yet implemented');
      case AIProvider.huggingface:
        // TODO: Implement Hugging Face service when ready
        throw UnimplementedError('Hugging Face API is not yet implemented');
    }
  }
}

