import 'package:flutter/material.dart';

/// Terms of Service Page - Comprehensive terms covering all legal requirements
/// Complies with: App Store, Play Store, and general best practices
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLastUpdated(),
            const SizedBox(height: 24),
            _buildIntro(),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Acceptance of Terms',
              content: '''
By accessing or using the Foody mobile application ("App", "Service"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.

These Terms constitute a legally binding agreement between you and Foody. Your use of the App is also governed by our Privacy Policy.
''',
            ),
            _buildSection(
              title: '2. Eligibility',
              content: '''
You must be at least 13 years old to use Foody. By using the App, you represent and warrant that:
• You are at least 13 years of age
• You have the legal capacity to enter into these Terms
• You will comply with these Terms and all applicable laws and regulations
• All information you provide is accurate and current

If you are under 18, you confirm that you have obtained parental or guardian consent to use this App.
''',
            ),
            _buildSection(
              title: '3. Description of Service',
              content: '''
Foody provides:
• AI-powered food image analysis using Google Gemini API for calorie tracking
• Personalized nutrition recommendations based on your profile
• Daily calorie and macronutrient tracking
• Progress monitoring toward your health goals
• Barcode scanning for packaged foods
• Push notifications for nutrition reminders

Technical Implementation:
The App uses Google's Gemini AI model (Gemini 2.5 Flash Lite) to analyze food images. When you take or upload a photo of food, the image is sent to Google's servers for processing. The AI identifies food items, estimates portions, and calculates nutritional information.

The Service is provided "as is" and we reserve the right to modify, suspend, or discontinue any part of the Service at any time.
''',
            ),
            _buildSection(
              title: '4. User Account and Registration',
              content: '''
4.1 Account Creation:
• You must create an account using Google Sign-In
• You are responsible for maintaining the confidentiality of your account
• You are responsible for all activities under your account
• You must notify us immediately of any unauthorized access

4.2 Account Information:
• You agree to provide accurate, current, and complete information
• You agree to update your information to keep it accurate
• We reserve the right to suspend or terminate accounts with false information
''',
            ),
            _buildSection(
              title: '5. Acceptable Use',
              content: '''
You agree NOT to:
• Use the App for any illegal purpose or in violation of any laws
• Upload content that is offensive, harmful, or inappropriate
• Attempt to gain unauthorized access to the App or its systems
• Interfere with or disrupt the App or servers
• Use automated systems (bots, scrapers) to access the App
• Reverse engineer, decompile, or disassemble the App
• Remove or modify any copyright, trademark, or proprietary notices
• Impersonate any person or entity
• Harass, abuse, or harm other users
• Upload viruses or malicious code

Violation of these terms may result in immediate account termination.
''',
            ),
            _buildSection(
              title: '6. User Content',
              content: '''
6.1 Content You Provide:
• You retain ownership of photos and data you upload
• You grant us a license to use your content to provide the Service (e.g., analyze food images via Google Gemini API)
• We do not claim ownership of your personal content
• You can delete your content at any time from the App

6.2 Content License:
By uploading content, you grant Foody a worldwide, non-exclusive, royalty-free license to use, store, and process your content solely for providing and improving the Service. This includes sending your food images to Google Gemini API for nutritional analysis.

6.3 Google Gemini API Processing:
• Your food images are transmitted to Google's servers for AI processing
• Google processes the images according to their Gemini API Terms
• Images are used only for real-time nutritional analysis
• We do not permanently store your images on Google's servers
• Google's data handling is governed by their privacy policy

6.4 Content Responsibility:
• You are solely responsible for your content
• You confirm you have rights to upload your content
• You agree not to upload inappropriate or illegal content
• You understand that uploaded images will be processed by Google Gemini API
''',
            ),
            _buildSection(
              title: '7. Intellectual Property',
              content: '''
7.1 Our Property:
• The App, including all content, features, and functionality, is owned by Foody
• All trademarks, logos, and service marks are owned by Foody or licensors
• All content is protected by copyright, trademark, and other laws

7.2 Limited License:
We grant you a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes, subject to these Terms.
''',
            ),
            _buildSection(
              title: '8. Nutritional Information Disclaimer',
              content: '''
IMPORTANT MEDICAL DISCLAIMER:

• Foody provides nutritional information for educational purposes only
• Information is NOT medical advice and should not replace professional consultation
• Nutritional data is AI-generated and may contain errors or inaccuracies
• Always verify nutritional information, especially for dietary restrictions or allergies
• Consult healthcare professionals before making significant dietary changes
• We are not liable for health consequences from relying on our nutritional data
• This App is not intended to diagnose, treat, cure, or prevent any disease

By using Foody, you acknowledge these limitations and agree to use the information at your own risk.
''',
            ),
            _buildSection(
              title: '9. Subscription and Payment',
              content: '''
9.1 Free Service:
Currently, Foody is provided free of charge. We reserve the right to introduce subscription plans or premium features in the future.

9.2 Future Paid Features:
If we introduce paid features:
• You will be notified in advance
• Pricing will be clearly displayed
• Subscriptions may be billed through Apple App Store or Google Play Store
• Cancellation policies will be provided at the time of purchase
• Payment terms will be governed by Apple/Google's terms
''',
            ),
            _buildSection(
              title: '10. Third-Party Services',
              content: '''
The App integrates with third-party services:
• Google Sign-In for authentication
• Google Firebase for data storage and messaging
• AWS Lambda for cloud computing and serverless functions
• Google Gemini API (Gemini 2.5 Flash Lite model) for AI-powered nutritional analysis

Important - Google Gemini API Usage:
When you upload or capture a food image in Foody, that image is sent to Google's Gemini API for processing. The API analyzes the image to identify food items and estimate nutritional information. This is a core feature of the App and cannot be disabled.

By using Foody, you also agree to:
• Google's Privacy Policy: https://policies.google.com/privacy
• Google Gemini API Terms of Service: https://ai.google.dev/gemini-api/terms
• Firebase Terms of Service: https://firebase.google.com/terms

We are not responsible for third-party services' performance, availability, or policies. Google's handling of your data is governed by their own privacy policy and terms of service.
''',
            ),
            _buildSection(
              title: '11. Disclaimer of Warranties',
              content: '''
THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:

• Implied warranties of merchantability
• Fitness for a particular purpose
• Non-infringement
• Accuracy, reliability, or completeness of content
• Uninterrupted or error-free operation
• Security of data transmission

We do not guarantee that the App will meet your requirements or that it will be available at all times.
''',
            ),
            _buildSection(
              title: '12. Limitation of Liability',
              content: '''
TO THE MAXIMUM EXTENT PERMITTED BY LAW:

• We are not liable for any indirect, incidental, special, consequential, or punitive damages
• We are not liable for loss of profits, revenue, data, or use
• We are not liable for health consequences from using nutritional information
• Our total liability shall not exceed the amount you paid us (if any) in the past 12 months

Some jurisdictions do not allow limitation of liability, so these limitations may not apply to you.
''',
            ),
            _buildSection(
              title: '13. Indemnification',
              content: '''
You agree to indemnify, defend, and hold harmless Foody and its officers, directors, employees, and agents from any claims, liabilities, damages, losses, and expenses (including legal fees) arising from:

• Your use of the App
• Your violation of these Terms
• Your violation of any rights of another party
• Your content uploaded to the App
• Your violation of any applicable laws
''',
            ),
            _buildSection(
              title: '14. Privacy and Data Protection',
              content: '''
Your use of the App is also governed by our Privacy Policy, which describes how we collect, use, and protect your personal information. By using the App, you consent to our data practices as described in the Privacy Policy.
''',
            ),
            _buildSection(
              title: '15. App Store Terms',
              content: '''
15.1 Apple App Store:
If you download the App from the Apple App Store, you acknowledge that:
• These Terms are between you and Foody, not Apple
• Apple has no obligation to provide support for the App
• Apple is not responsible for addressing any claims relating to the App
• Apple is a third-party beneficiary of these Terms

15.2 Google Play Store:
If you download the App from Google Play Store, you agree to comply with Google's Terms of Service and acknowledge Google's role as the distribution platform.
''',
            ),
            _buildSection(
              title: '16. Updates and Changes',
              content: '''
16.1 App Updates:
• We may release updates, patches, or new versions
• Updates may be required for continued use
• Some features may change or be discontinued

16.2 Terms Updates:
• We may modify these Terms at any time
• Material changes will be notified through the App
• Continued use after changes constitutes acceptance
• The "Last Updated" date will reflect the most recent changes
''',
            ),
            _buildSection(
              title: '17. Termination',
              content: '''
17.1 Your Rights:
• You may stop using the App at any time
• You may delete your account through the App settings

17.2 Our Rights:
We may suspend or terminate your access if:
• You violate these Terms
• You engage in fraudulent or illegal activities
• Required by law
• We discontinue the Service

17.3 Effect of Termination:
• Your license to use the App ends immediately
• You must cease all use of the App
• We may delete your data in accordance with our Privacy Policy
• Provisions that should survive termination will remain in effect
''',
            ),
            _buildSection(
              title: '18. Geographic Restrictions',
              content: '''
The App is controlled and operated from the United States. We make no representation that the App is appropriate or available for use in other locations. Access from jurisdictions where the content is illegal is prohibited.
''',
            ),
            _buildSection(
              title: '19. Governing Law and Dispute Resolution',
              content: '''
19.1 Governing Law:
These Terms are governed by the laws of the United States and the State of California, without regard to conflict of law provisions.

19.2 Dispute Resolution:
• First, contact us to resolve disputes informally
• If informal resolution fails, disputes will be resolved through binding arbitration
• You waive your right to a jury trial or class action lawsuit
• Arbitration will be conducted under the American Arbitration Association rules

19.3 Exceptions:
Either party may seek injunctive relief in court to protect intellectual property rights.
''',
            ),
            _buildSection(
              title: '20. Severability',
              content: '''
If any provision of these Terms is found to be invalid or unenforceable, the remaining provisions will remain in full force and effect.
''',
            ),
            _buildSection(
              title: '21. Entire Agreement',
              content: '''
These Terms, together with our Privacy Policy, constitute the entire agreement between you and Foody regarding the use of the App and supersede all prior agreements.
''',
            ),
            _buildSection(
              title: '22. Contact Information',
              content: '''
If you have questions about these Terms, please contact us:

Email: support@foodyapp.com
Response Time: Within 48 hours

For legal inquiries:
Email: legal@foodyapp.com

Mailing Address:
Foody App
[Your Company Address]
[City, State, ZIP]
United States
''',
            ),
            _buildSection(
              title: '23. Acknowledgment',
              content: '''
BY USING THE FOODY APP, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO BE BOUND BY THESE TERMS OF SERVICE.
''',
            ),
            const SizedBox(height: 32),
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            color: Color(0xFFFF6B6B),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Last Updated: ${_getFormattedDate()}',
            style: const TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return const Text(
      'Welcome to Foody! These Terms of Service ("Terms") govern your use of the Foody mobile application and services. Please read them carefully.\n\nBy creating an account or using our App, you agree to these Terms. If you do not agree, please do not use our App.',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.6,
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFFF6B6B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.trim(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.8,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.2),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.gavel,
            color: Color(0xFFFF6B6B),
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Thank you for using Foody!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We are committed to providing you with the best nutrition tracking experience while protecting your rights and ensuring transparency.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    // You can update this date when you actually update the terms
    return 'October 21, 2025';
  }
}
