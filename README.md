# 🍽️ Foody

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-2.18.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-2.18.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg?style=for-the-badge)](https://www.gnu.org/licenses/gpl-3.0)

</div>

<div align="center">
Your AI-powered food analysis assistant
</div>

##  Overview

Foody is an intelligent food analysis and health tracking application built with Flutter. It leverages advanced AI technology to analyze food images and provide detailed nutritional information. The app helps users make informed dietary choices by:

- 📸 Taking or selecting food photos for instant nutritional analysis
- 🔍 Identifying food items and their nutritional content using AI
- 📊 Tracking daily calorie intake and nutritional goals
- 📈 Monitoring macronutrients (protein, carbs, fat)
- ⭐ Providing health scores for food choices
- 📱 Offering an intuitive, modern interface for health management

Built with clean architecture and MVVM patterns, Foody ensures a robust, maintainable, and scalable codebase while delivering a seamless user experience.

## ✨ Features

### 🎯 Core Features
- 📸 Advanced image analysis
- 📊 Health metrics tracking
- 📈 Interactive data visualization
- 🔒 Secure data persistence
- 🌙 Modern Material Design UI

### 🛠️ Technical Features
- Clean Architecture with MVVM pattern
- Dependency Injection
- State Management
- Environment Configuration
- Responsive Design

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=2.18.0)
- Dart SDK
- Android Studio / Xcode
- VS Code (recommended)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/mohammadaminrez/foody.git
   cd foody
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Create `.env` file in root directory with the following:
     ```env
     OPENAI_API_KEY=your_openai_api_key
     ```
   - Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
   - Replace `your_openai_api_key` with your actual OpenAI API key
   - Never share or commit your API key to version control
   - Keep your API key secure and private

4. **Run the app**
   ```bash
   flutter run
   ```

## 🛠️ Tech Stack

### Core
- **Framework**: Flutter
- **Language**: Dart
- **Architecture**: Clean Architecture + MVVM

### State Management & DI
- Provider
- GetIt

### Storage & Network
- Shared Preferences
- HTTP Client

### UI Components
- Flutter SpinKit
- Google Fonts
- FL Chart
- Shimmer

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

Copyright © 2024 Amin Rezaei Sepehr

Foody is a free software licensed under GPL v3.0. It is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Being Open Source doesn't mean you can just make a copy of the app and upload it on playstore or sell a closed source copy of the same.

Read the following carefully:
1. Any copy of a software under GPL must be under same license. So you can't upload the app on a closed source app repository like PlayStore/AppStore without distributing the source code.
2. You can't sell any copied/modified version of the app under any "non-free" license.
   You must provide the copy with the original software or with instructions on how to obtain original software,
   should clearly state all changes, should clearly disclose full source code, should include same license
   and all copyrights should be retained.

In simple words, You can ONLY use the source code of this app for `Open Source` Project under `GPL v3.0` or later with all your source code CLEARLY DISCLOSED on any code hosting platform like GitHub, with clear INSTRUCTIONS on how to obtain the original software, should clearly STATE ALL CHANGES made and should RETAIN all copyrights.

Use of this software under any "non-free" license is NOT permitted.

See the [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0) for more details.

## 📞 Contact

[![Email](https://img.shields.io/badge/Email-mohammadaminrez@gmail.com-D14836?style=for-the-badge&logo=gmail&logoColor=white)](mailto:mohammadaminrez@gmail.com)

---

<div align="center">
  Made with ❤️ by Amin
</div>
