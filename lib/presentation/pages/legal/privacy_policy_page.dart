import 'package:flutter/material.dart';

/// Privacy Policy Page - Comprehensive policy covering all legal requirements
/// Complies with: App Store, Play Store, GDPR, CCPA, Google OAuth
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

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
          'Privacy Policy',
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
              title: '1. Information We Collect',
              content: '''
1.1 Information You Provide:
• Account Information: When you sign in with Google, we collect your name, email address, and profile picture from your Google account.
• Profile Data: Age, gender, weight, height, activity level, and weight goals that you provide during onboarding.
• Food Data: Photos of meals you upload and nutritional information from our analysis.
• Health Metrics: Daily calorie intake, macronutrient breakdown, and progress tracking data.

1.2 Automatically Collected Information:
• Device Information: Device type, operating system, and app version.
• Usage Data: App interactions, features used, and session duration.
• Log Data: Error logs and crash reports to improve app stability.

1.3 Information from Third Parties:
• Google Sign-In: We receive basic profile information from Google OAuth when you sign in.
• Firebase Services: Authentication and cloud messaging services provided by Google Firebase.
''',
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              content: '''
We use your information to:
• Provide and maintain the Foody service
• Calculate personalized calorie and nutrition recommendations
• Analyze food images using Google Gemini API to provide nutritional information
• Track your daily nutrition and progress toward goals
• Send you important notifications about your nutrition tracking
• Improve app performance and fix bugs
• Respond to your support requests
• Comply with legal obligations

Image Processing:
When you upload a food image, it is sent to Google's Gemini API for AI-powered nutritional analysis. The image is processed to extract information about food items, portion sizes, and nutritional content. We do not store your images permanently on Google's servers - they are only used for real-time analysis.

We do NOT:
• Sell your personal information to third parties
• Share your data for advertising purposes
• Use your food photos for any purpose other than providing you nutritional analysis
• Train AI models on your food images without explicit consent
• Store your images on Google's servers after analysis is complete
''',
            ),
            _buildSection(
              title: '3. Data Storage and Security',
              content: '''
• Your data is stored securely on Google Firebase servers with industry-standard encryption
• Local data on your device is stored in encrypted databases
• We implement appropriate security measures to protect against unauthorized access
• Regular security audits and updates are performed
• Data is transmitted using secure HTTPS connections
• We retain your data only as long as necessary to provide our services
''',
            ),
            _buildSection(
              title: '4. Your Privacy Rights',
              content: '''
4.1 GDPR Rights (EU Users):
• Right to access your personal data
• Right to rectification of inaccurate data
• Right to erasure ("right to be forgotten")
• Right to restrict processing
• Right to data portability
• Right to object to processing
• Right to withdraw consent at any time

4.2 CCPA Rights (California Users):
• Right to know what personal information is collected
• Right to know if personal information is sold or disclosed
• Right to say no to the sale of personal information
• Right to access your personal information
• Right to equal service and price
• Right to request deletion of your personal information

4.3 How to Exercise Your Rights:
To exercise any of these rights, please contact us at: support@foodyapp.com
We will respond to your request within 30 days.
''',
            ),
            _buildSection(
              title: '5. Data Sharing and Disclosure',
              content: '''
We may share your information with:

• Google Services: Your food images are sent to Google Gemini API for nutritional analysis. Google Firebase is used for authentication and data storage.
• AWS Lambda: For cloud computing and serverless functions
• Legal Requirements: When required by law, court order, or government regulation
• Business Transfers: In case of merger, acquisition, or sale of assets (you will be notified)
• With Your Consent: When you explicitly authorize us to share your information

Important Note About Google Gemini API:
When you take or upload a food photo, that image is transmitted to Google's Gemini API for AI-powered analysis. Google processes the image to identify food items and estimate nutritional information. This processing is essential for the core functionality of Foody. By using the app, you consent to this data sharing with Google for analysis purposes only.

We do NOT share your personal information for marketing purposes.
''',
            ),
            _buildSection(
              title: '6. Children\'s Privacy',
              content: '''
Foody is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us, and we will delete such information.
''',
            ),
            _buildSection(
              title: '7. International Data Transfers',
              content: '''
Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy and applicable laws.
''',
            ),
            _buildSection(
              title: '8. Cookies and Tracking',
              content: '''
We use minimal tracking technologies:
• Essential cookies for authentication and app functionality
• Analytics to understand app usage and improve user experience
• No third-party advertising cookies

You can manage cookie preferences through your device settings.
''',
            ),
            _buildSection(
              title: '9. Third-Party Services',
              content: '''
Our app uses the following third-party services:

• Google Sign-In: For authentication (Google Privacy Policy applies)
• Google Firebase: For authentication, storage, and messaging
• AWS Lambda: For cloud computing and serverless functions
• Google Gemini API (Gemini 2.5 Flash Lite): For AI-powered nutritional information extraction from food images

Your food images are processed by Google's Gemini API to provide nutritional analysis. By using Foody, you acknowledge that your food images are sent to Google's servers for processing. Google's Privacy Policy and Terms of Service apply to the use of Gemini API.

Each third-party service has its own privacy policy. We encourage you to review them:
• Google Privacy Policy: https://policies.google.com/privacy
• Firebase Privacy & Security: https://firebase.google.com/support/privacy
• AWS Privacy Notice: https://aws.amazon.com/privacy
• Google Gemini API Terms: https://ai.google.dev/gemini-api/terms
''',
            ),
            _buildSection(
              title: '10. Data Retention',
              content: '''
• Account data is retained while your account is active
• You can request deletion of your account at any time
• After account deletion, we retain some data for legal and backup purposes for up to 90 days
• Anonymized analytics data may be retained indefinitely
''',
            ),
            _buildSection(
              title: '11. Push Notifications',
              content: '''
We may send you push notifications for:
• Daily nutrition reminders
• Goal achievement celebrations
• Important app updates

You can disable notifications in your device settings at any time.
''',
            ),
            _buildSection(
              title: '12. Changes to This Privacy Policy',
              content: '''
We may update this Privacy Policy from time to time. We will notify you of any changes by:
• Posting the new Privacy Policy in the app
• Updating the "Last Updated" date
• Sending you a notification for material changes

Continued use of Foody after changes constitutes acceptance of the updated policy.
''',
            ),
            _buildSection(
              title: '13. Contact Us',
              content: '''
If you have any questions, concerns, or requests regarding this Privacy Policy or your personal data, please contact us:

Email: support@foodyapp.com
Response Time: Within 48 hours

For GDPR-related inquiries (EU users):
Email: gdpr@foodyapp.com

For CCPA-related inquiries (California users):
Email: privacy@foodyapp.com
''',
            ),
            _buildSection(
              title: '14. Legal Basis for Processing (GDPR)',
              content: '''
We process your personal data based on:
• Consent: You have given clear consent for specific purposes
• Contract: Processing is necessary to fulfill our service to you
• Legal Obligation: Processing is required by law
• Legitimate Interest: Processing is necessary for our legitimate interests (e.g., fraud prevention)
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
      'Your privacy is important to us. This Privacy Policy explains how Foody ("we", "us", or "our") collects, uses, shares, and protects your personal information when you use our mobile application.\n\nBy using Foody, you agree to the collection and use of information in accordance with this policy.',
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
      ),
      child: const Column(
        children: [
          Icon(
            Icons.verified_user,
            color: Color(0xFFFF6B6B),
            size: 32,
          ),
          SizedBox(height: 12),
          Text(
            'Your data is protected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'We are committed to protecting your privacy and handling your data with care and transparency.',
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
    // You can update this date when you actually update the policy
    return 'October 21, 2025';
  }
}
