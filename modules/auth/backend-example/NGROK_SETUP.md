# Using ngrok for Development

ngrok creates a public URL that tunnels to your local server, so your Flutter app can access it from anywhere.

## Step 1: Install ngrok

1. Download ngrok from: https://ngrok.com/download
2. Extract the `ngrok.exe` file to a folder (e.g., `C:\ngrok\`)
3. Add ngrok to your PATH, or use the full path

## Step 2: Start Your Backend Server

Make sure your backend server is running:
```bash
cd modules/auth/backend-example
npm start
```

## Step 3: Start ngrok

Open a **new terminal** and run:
```bash
ngrok http 3000
```

You'll see output like:
```
Forwarding    https://abc123.ngrok.io -> http://localhost:3000
```

**Copy the HTTPS URL** (e.g., `https://abc123.ngrok.io`)

## Step 4: Update Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** → **Credentials**
3. Click your OAuth 2.0 Client ID
4. Under **Authorized redirect URIs**, add:
   ```
   https://YOUR-NGROK-URL.ngrok.io/auth/callback
   ```
   (Replace `YOUR-NGROK-URL` with your actual ngrok URL)
5. Click **Save**

## Step 5: Update Flutter App

1. Open `modules/auth/lib/services/email_config.dart`
2. Update the backend URL:
   ```dart
   static const String backendApiUrl = 'https://YOUR-NGROK-URL.ngrok.io';
   ```
   (Replace with your actual ngrok URL)

## Step 6: Re-authorize Gmail API

Since the redirect URI changed, you need to re-authorize:

1. Visit: `https://YOUR-NGROK-URL.ngrok.io/auth`
2. Sign in and authorize
3. You'll be redirected back successfully

## Step 7: Test

Now your Flutter app can access the backend from anywhere, as long as:
- Your backend server is running
- ngrok is running (keep both terminals open!)

## Important Notes

⚠️ **ngrok URLs change each time you restart ngrok** (unless you have a paid account with a static URL)

- Free ngrok URLs are temporary
- For production, use Option 2 (Cloud Deployment)
- Keep both the backend server and ngrok running while testing

## Troubleshooting

### "redirect_uri_mismatch" error
- Make sure you added the ngrok URL to Google Cloud Console redirect URIs
- The URL must match exactly (including `https://`)

### ngrok connection refused
- Make sure your backend server is running on port 3000
- Check that ngrok is pointing to the correct port


