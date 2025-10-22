# Google OAuth Consent Screen Setup

## Issue: Privacy Policy and Terms of Service Links Not Working

The privacy policy and terms of service links shown in the Google Sign-In popup are controlled by your **Google Cloud Console OAuth consent screen configuration**, not by the app code.

## Solution

### Step 1: Access Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Foody project
3. Navigate to **APIs & Services** > **OAuth consent screen**

### Step 2: Configure Application Links

Scroll down to the **Application links** section and configure:

1. **Application home page** (optional but recommended)
2. **Application privacy policy link** (REQUIRED)
3. **Application terms of service link** (REQUIRED)

### Step 3: Get Public URLs

You have **three options** for hosting your privacy policy and terms of service:

#### Option 1: GitHub Pages (Recommended - Free & Easy)

1. Create a `docs` folder in your repository root
2. Create two HTML files:
   - `docs/privacy-policy.html`
   - `docs/terms-of-service.html`
3. Enable GitHub Pages in repository settings (Settings > Pages)
4. Set source to `main` branch and `/docs` folder
5. Your URLs will be:
   - `https://YOUR_USERNAME.github.io/Foody/privacy-policy.html`
   - `https://YOUR_USERNAME.github.io/Foody/terms-of-service.html`

#### Option 2: Firebase Hosting (If you're using Firebase)

1. Deploy a simple web page with your privacy policy and terms
2. URLs: `https://YOUR_PROJECT.web.app/privacy-policy`
3. Commands:
   ```bash
   firebase init hosting
   firebase deploy --only hosting
   ```

#### Option 3: Custom Web Server

Host the pages on your own domain or any web hosting service.

### Step 4: Update OAuth Consent Screen

1. In Google Cloud Console > OAuth consent screen
2. Scroll to **Application links**
3. Enter your public URLs:
   - **Privacy policy link**: Your privacy policy URL
   - **Terms of service link**: Your terms of service URL
4. Click **Save and Continue**
5. Click **Back to Dashboard**

### Step 5: Verify the Fix

1. Sign out from your app
2. Try signing in with Google again
3. Click on "privacy policy" and "terms of service" links
4. They should now open in a browser

## Creating HTML Versions of Your Legal Pages

Your app already has `PrivacyPolicyPage` and `TermsOfServicePage` in Flutter, but you need public web-accessible versions.

### Quick Solution: Export to HTML

I can help you create HTML versions of your existing legal pages. These will be:
- Standalone HTML files
- Mobile-responsive
- Match your app's styling
- Ready to deploy

## Important Notes

- **URLs must be publicly accessible** (not localhost or private IPs)
- **URLs must use HTTPS** (not HTTP)
- **Changes may take a few minutes to propagate**
- If your OAuth consent screen is in "Testing" mode, only test users can sign in
- For production, you'll need to submit for verification if you haven't already

## Testing

After updating the URLs:
1. Clear app data or uninstall/reinstall the app
2. Try signing in with Google
3. The consent screen should now have working links

## Troubleshooting

**Links still don't work?**
- Wait 5-10 minutes for changes to propagate
- Make sure URLs are publicly accessible
- Check that URLs use HTTPS
- Verify you saved the OAuth consent screen settings

**"Verification required" message?**
- For production apps with sensitive scopes, Google requires verification
- Submit your app for verification in the OAuth consent screen

**Still in "Testing" mode?**
- Add test users in the OAuth consent screen
- Or publish your app for production use

## Next Steps

Would you like me to:
1. Create HTML versions of your privacy policy and terms of service?
2. Set up GitHub Pages deployment?
3. Configure Firebase Hosting?

Just let me know which option works best for you!

