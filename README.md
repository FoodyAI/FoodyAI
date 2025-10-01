# Foody

AI-powered food analysis and calorie tracking app built with Flutter.

## Features
- Analyze food photos to extract calories and macros (protein, carbs, fat)
- Choose AI provider in onboarding or settings: OpenAI (recommended) or Gemini
- Track daily intake with timeline and per-day grouping
- Barcode scanning via Open Food Facts
- Onboarding with measurements, activity, and weight goals
- Light/Dark themes, responsive UI

## Tech
- Flutter, Dart, Material 3
- Clean Architecture + MVVM
- State: Provider, DI: GetIt
- Storage: SharedPreferences
- Networking: http

## Quick Start
1) Install
```bash
flutter pub get
```

2) Environment
Create a `.env` file in the project root:
```env
OPENAI_API_KEY=your_openai_api_key
GEMINI_API_KEY=your_gemini_api_key
```
- OpenAI key: https://platform.openai.com/api-keys
- Gemini key: https://makersuite.google.com/app/apikey

3) Run
```bash
flutter run
```

## AI Providers
- OpenAI GPT-4o mini (default, recommended)
- Google Gemini 2.5 Flash
You can select your preferred provider during onboarding or later in Profile → Settings → AI Provider.

## Project Structure
- `lib/presentation` – Views, ViewModels, Widgets
- `lib/domain` – Entities, UseCases, Repositories
- `lib/data` – Models, Datasources, Repositories
- `lib/di` – Service locator (GetIt)
- `lib/core` – Themes, constants, utils

## Contributing
Please read `CONTRIBUTING.md` before opening issues or PRs.

## License
GPL-3.0 © 2024 Mohammad Amin Rezaei Sepehr
