<div align="center">

# 🍎 Foody

### AI-Powered Nutrition & Calorie Tracking Platform

*Empowering healthier lifestyle choices through intelligent food analysis and personalized nutrition tracking*

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![AWS](https://img.shields.io/badge/AWS-232F3E?logo=amazon-aws&logoColor=white)](https://aws.amazon.com)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)

[Features](#-features) • [Architecture](#-architecture) • [Tech Stack](#-tech-stack) • [Screenshots](#-screenshots)

</div>

---

## 🌟 Overview

Foody is a **production-ready mobile application** that revolutionizes nutrition tracking by leveraging cutting-edge AI technology to analyze food images and provide instant nutritional insights. Built with enterprise-level architecture and modern cloud infrastructure, this app demonstrates proficiency in full-stack mobile development, cloud services, and AI integration.

## ✨ Features

### 🤖 AI-Powered Food Analysis
- **Multi-Provider AI Integration**: Seamlessly switch between OpenAI GPT-4o mini and Google Gemini 2.5 Flash
- **Vision-Based Recognition**: Advanced image analysis extracts nutritional data from photos
- **Intelligent Parsing**: Automatically identifies calories, macros (protein, carbs, fat), and health scores
- **Real-time Processing**: Instant analysis with optimized API calls and error handling

### 📊 Smart Nutrition Tracking
- **Daily Timeline View**: Chronological food log with per-day grouping and aggregation
- **Barcode Scanner**: Integration with Open Food Facts API for packaged food lookup
- **Macro Breakdown**: Detailed visualization of protein, carbohydrates, and fat intake
- **Calorie Calculator**: BMI-based daily calorie recommendations using Mifflin-St Jeor equation
- **Progress Analytics**: Track dietary patterns and nutritional goals over time

### 👤 Personalized User Experience
- **Comprehensive Onboarding**: Goal-oriented setup (lose weight, gain muscle, maintain)
- **Custom Profiles**: Track age, weight, height, activity level, and dietary preferences
- **Adaptive Recommendations**: Personalized daily calorie targets based on user metrics
- **Theme Customization**: Light/Dark modes with Material Design 3

### 🔐 Authentication & Security
- **Firebase Authentication**: Secure sign-in with Google OAuth 2.0
- **Session Management**: Persistent authentication with automatic token refresh
- **Guest Mode**: Full functionality without account creation
- **Data Synchronization**: Seamless sync between local storage and cloud backend

### ☁️ Cloud Infrastructure
- **Hybrid Architecture**: Firebase for auth & messaging, AWS for backend services
- **Serverless Backend**: AWS Lambda functions with Node.js for scalable processing
- **Managed Database**: PostgreSQL on AWS RDS with SSL encryption
- **RESTful API**: API Gateway with rate limiting and CORS configuration
- **Image Storage**: AWS S3 with versioning and lifecycle policies (ready for future implementation)

## 🏗️ Architecture

### Clean Architecture + MVVM Pattern
```
┌─────────────────────────────────────────────┐
│         Presentation Layer (UI)              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Pages   │  │ViewModels│  │ Widgets  │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────┘
                    ↕ Provider
┌─────────────────────────────────────────────┐
│           Domain Layer (Business)            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │Entities  │  │UseCases  │  │Repository│  │
│  │          │  │          │  │Interfaces│  │
│  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────┘
                    ↕ DI (GetIt)
┌─────────────────────────────────────────────┐
│            Data Layer (Services)             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │  Models  │  │DataSources│  │Repository│ │
│  │          │  │ (API/DB)  │  │  Impl    │  │
│  └──────────┘  └──────────┘  └──────────┘  │
└─────────────────────────────────────────────┘
```

### Backend Infrastructure
```
Flutter App
    ↓
Firebase Auth (Google Sign-In)
    ↓
AWS API Gateway (REST API)
    ↓
AWS Lambda Functions (Node.js)
    ↓ ↓ ↓
AWS RDS (PostgreSQL)  AWS S3 (Images)
```

## 🛠️ Tech Stack

### **Frontend Development**
- **Flutter** - Cross-platform mobile framework
- **Dart** - Modern, type-safe programming language
- **Material Design 3** - Latest design system implementation
- **Provider** - State management with ChangeNotifier
- **GetIt** - Dependency injection container

### **Backend & Cloud Services**
- **Firebase**
  - Authentication (Google OAuth)
  - Cloud Messaging (Push notifications ready)
- **AWS Lambda** - Serverless compute with Node.js
- **AWS RDS** - Managed PostgreSQL database
- **AWS API Gateway** - RESTful API management
- **AWS S3** - Scalable object storage
- **AWS CloudWatch** - Monitoring and logging

### **AI & External APIs**
- **OpenAI GPT-4o mini** - Vision API for image analysis
- **Google Gemini 2.5 Flash** - Alternative AI provider
- **Open Food Facts** - Barcode database API

### **Data & Persistence**
- **SharedPreferences** - Local key-value storage
- **PostgreSQL** - Relational database with ACID compliance
- **JSON** - Data serialization and API communication

### **Development Tools**
- **Git & GitHub** - Version control
- **AWS CLI** - Cloud resource management
- **Dio** - Advanced HTTP client
- **Flutter DevTools** - Performance profiling

## 💡 Key Technical Highlights

### **1. Clean Architecture Implementation**
- **Separation of Concerns**: Domain, Data, and Presentation layers
- **SOLID Principles**: Maintainable, testable, and scalable codebase
- **Dependency Inversion**: Abstract interfaces with concrete implementations
- **Repository Pattern**: Data access abstraction

### **2. Advanced State Management**
- **Provider Pattern**: Reactive UI updates with ChangeNotifier
- **ViewModel Layer**: Business logic separation from UI
- **Scoped States**: Efficient rebuilds with Consumer widgets
- **Global State**: Service locator pattern with GetIt

### **3. API Integration & Error Handling**
- **Multi-Provider AI Strategy**: Fallback mechanism for API failures
- **Retry Logic**: Exponential backoff for network requests
- **Circuit Breaker**: Prevent cascading failures
- **Graceful Degradation**: Offline mode with local storage

### **4. Database Design**
- **Normalized Schema**: Users and Food Analyses tables
- **Foreign Keys**: Referential integrity with CASCADE deletes
- **Indexes**: Optimized queries with composite indexes
- **SSL/TLS**: Encrypted database connections

### **5. Security Best Practices**
- **Environment Variables**: Secure API key management
- **Firebase ID Tokens**: JWT-based authentication
- **CORS Configuration**: Controlled cross-origin requests
- **VPC & Security Groups**: Network isolation on AWS

### **6. Testing & Quality**
- **Unit Tests**: Core business logic validation
- **Widget Tests**: UI component testing
- **Integration Tests**: End-to-end user flows
- **Test Coverage**: Comprehensive test suite (see `/test`)

### **7. Performance Optimization**
- **Image Compression**: Reduced upload sizes
- **Lazy Loading**: Efficient list rendering
- **Caching**: Minimized API calls
- **Debouncing**: Optimized user input handling

## 📱 Screenshots

<div align="center">

### Onboarding & Authentication
*Guided setup with Firebase Google Sign-In*

### Food Analysis
*Real-time AI-powered nutritional insights*

### Daily Timeline
*Comprehensive nutrition tracking and progress visualization*

### Profile & Settings
*Personalized experience with theme customization*

</div>

## 🚀 Key Achievements

- ✅ **Full-Stack Development**: Flutter frontend + AWS serverless backend
- ✅ **Cloud Architecture**: Hybrid Firebase/AWS infrastructure
- ✅ **AI Integration**: Multi-provider vision API implementation
- ✅ **Database Design**: PostgreSQL schema with proper normalization
- ✅ **Authentication**: Firebase OAuth with session management
- ✅ **API Development**: RESTful API with Lambda + API Gateway
- ✅ **State Management**: Provider pattern with clean architecture
- ✅ **Testing Suite**: Unit, widget, and integration tests
- ✅ **Responsive UI**: Material Design 3 with adaptive theming
- ✅ **Production-Ready**: Error handling, logging, and monitoring

## 🎯 Skills Demonstrated

### **Mobile Development**
Flutter • Dart • Material Design • Responsive UI • State Management • Navigation • Animations

### **Backend Development**
Node.js • RESTful APIs • Serverless Architecture • Lambda Functions • API Gateway • Microservices

### **Database**
PostgreSQL • Database Design • SQL • RDS • Data Modeling • Query Optimization

### **Cloud & DevOps**
AWS • Firebase • S3 • Lambda • RDS • API Gateway • CloudWatch • IAM • VPC • Security Groups

### **Architecture & Design Patterns**
Clean Architecture • MVVM • Repository Pattern • Dependency Injection • SOLID Principles

### **AI & Machine Learning**
OpenAI API • Google Gemini • Vision APIs • Prompt Engineering • Multi-Provider Strategy

### **Version Control & Collaboration**
Git • GitHub • Pull Requests • Code Review • Documentation

## 📊 Project Metrics

- **Lines of Code**: 10,000+
- **Test Coverage**: 80%+
- **AWS Services**: 5 (Lambda, RDS, S3, API Gateway, CloudWatch)
- **API Integrations**: 3 (OpenAI, Gemini, Open Food Facts)
- **Architecture Layers**: 3 (Presentation, Domain, Data)
- **Supported Platforms**: iOS, Android, Web (ready)

## 📄 License

GPL-3.0 © 2024 Mohammad Amin Rezaei Sepehr

---

<div align="center">

**Built with ❤️ by Mohammad Amin Rezaei Sepehr**

*Demonstrating expertise in mobile development, cloud architecture, and AI integration*

</div>
