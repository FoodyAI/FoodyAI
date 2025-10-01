/// Available AI providers for food analysis
enum AIProvider {
  openai,
  gemini,
  claude,
  huggingface,
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI GPT-4o';
      case AIProvider.gemini:
        return 'Google Gemini';
      case AIProvider.claude:
        return 'Anthropic Claude';
      case AIProvider.huggingface:
        return 'Hugging Face';
    }
  }

  String get description {
    switch (this) {
      case AIProvider.openai:
        return 'Most accurate and reliable food analysis with excellent nutritional data';
      case AIProvider.gemini:
        return 'Fast and efficient with generous free tier, great for daily use';
      case AIProvider.claude:
        return 'Advanced reasoning with detailed nutritional insights';
      case AIProvider.huggingface:
        return 'Open-source models, requires technical setup';
    }
  }

  String get pricing {
    switch (this) {
      case AIProvider.openai:
        return '\$5 free credit';
      case AIProvider.gemini:
        return '60 requests/min free';
      case AIProvider.claude:
        return 'Paid only';
      case AIProvider.huggingface:
        return 'Free';
    }
  }

  bool get isRecommended {
    return this == AIProvider.openai;
  }

  bool get isFree {
    switch (this) {
      case AIProvider.openai:
        return false; // Has free credit but requires payment method
      case AIProvider.gemini:
        return true;
      case AIProvider.claude:
        return false;
      case AIProvider.huggingface:
        return true;
    }
  }
}
