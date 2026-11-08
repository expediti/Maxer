# Google Authentication Setup Guide

This guide walks you through configuring **Google OAuth 2.0** for Rexam with Supabase Auth on Android and Web.

---

## 1. Google Cloud Console Setup

1. Open the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project named **Rexam** or select your existing project.
3. Navigate to **APIs & Services** > **OAuth consent screen**:
   - User Type: **External**.
   - App Name: `Rexam`.
   - User Support Email: your email.
   - Developer Contact Information: your email.
   - Authorized Domains: add `supabase.co`.
   - Scopes: select `.../auth/userinfo.email`, `.../auth/userinfo.profile`, `openid`.
   - Save and continue.

---

## 2. Create Web Application Credentials (For Supabase Auth)

1. Navigate to **APIs & Services** > **Credentials**.
2. Click **Create Credentials** > **OAuth Client ID**.
3. Application Type: **Web application**.
4. Name: `Rexam Supabase Auth Backend`.
5. Under **Authorized redirect URIs**, add your Supabase project callback URL:
   ```
   https://<your-project-ref>.supabase.co/auth/v1/callback
   ```
   *(Find this in your Supabase Dashboard under Authentication > Providers > Google).*
6. Click **Create**.
7. Copy the generated **Client ID** and **Client Secret**.

---

## 3. Enable Google Provider in Supabase Dashboard

1. Open your [Supabase Dashboard](https://supabase.com/dashboard).
2. Go to **Authentication** > **Providers**.
3. Find **Google** and toggle it **Enabled**.
4. Paste your **Client ID** and **Client Secret** obtained in Step 2.
5. Click **Save**.

---

## 4. Mobile Deep Linking Configuration (Android)

Rexam uses the PKCE flow with deep linking so that after the candidate signs in via Google in their mobile browser, they are automatically redirected back into the Flutter app.

The Android Intent Filter is already configured in [AndroidManifest.xml](file:///home/amitsharma/Rexam/mobile/android/app/src/main/AndroidManifest.xml):

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="io.supabase.rexam"
        android:host="login-callback" />
</intent-filter>
```

### Add Redirect URL in Supabase
In the Supabase Dashboard:
1. Navigate to **Authentication** > **URL Configuration**.
2. Under **Redirect URLs**, add:
   ```
   io.supabase.rexam://login-callback
   ```
3. Save changes.

---

## 5. Testing the Flow in Flutter

1. In the app's Authentication screen, click **"Continue with Google"**.
2. The user will be redirected to the secure Google Sign-In consent screen.
3. Upon approval, Google redirects to `https://<project-ref>.supabase.co/auth/v1/callback`, which redirects to `io.supabase.rexam://login-callback`.
4. The Flutter app intercepts the URL, exchanges the auth code for a session token, and navigates the candidate directly to the **Profile Wizard** or **Discover Dashboard**.

