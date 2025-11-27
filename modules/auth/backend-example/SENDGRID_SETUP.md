# SendGrid Setup Guide

This guide will help you set up SendGrid to send verification emails for the UniFlow password reset feature.

## Why SendGrid?

- ✅ **Simple setup** - Just an API key, no OAuth flows
- ✅ **Works from anywhere** - No network restrictions
- ✅ **Free tier** - 100 emails/day forever
- ✅ **Production-ready** - Used by thousands of apps
- ✅ **Better deliverability** - Emails reach inboxes reliably

## Step 1: Create SendGrid Account

1. Go to [https://sendgrid.com/](https://sendgrid.com/)
2. Click **Start for Free** or **Sign Up**
3. Fill in your details:
   - Email address
   - Password
   - Company name (optional)
4. Verify your email address (check your inbox)

## Step 2: Get Your API Key

1. After logging in, go to **Settings** → **API Keys** (in the left sidebar)
2. Click **Create API Key** button (top right)
3. Choose **Full Access** (or **Restricted Access** with "Mail Send" permission)
4. Give it a name (e.g., "UniFlow Email Service")
5. Click **Create & View**
6. **IMPORTANT**: Copy the API key immediately - you won't be able to see it again!
   - It will look like: `SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
7. Save it somewhere safe (you'll need it in Step 4)

## Step 3: Verify Your Sender Email

SendGrid requires you to verify the email address you'll send from.

### Option A: Single Sender Verification (Recommended for Testing)

1. Go to **Settings** → **Sender Authentication** → **Single Sender Verification**
2. Click **Create New Sender**
3. Fill in the form:
   - **From Email Address**: Your email (e.g., `noreply@uniflow.app` or your personal email)
   - **From Name**: "UniFlow" (or your app name)
   - **Reply To**: Same as From Email
   - **Company Address**: Your address
   - **City, State, Zip**: Your location
   - **Country**: Your country
4. Click **Create**
5. **Check your email** and click the verification link
6. Once verified, you can use this email as your `FROM_EMAIL`

### Option B: Domain Authentication (Recommended for Production)

For production apps, verify your entire domain:

1. Go to **Settings** → **Sender Authentication** → **Domain Authentication**
2. Click **Authenticate Your Domain**
3. Follow the DNS setup instructions
4. Once verified, you can send from any email on that domain (e.g., `noreply@yourdomain.com`)

## Step 4: Update Your Backend Configuration

1. Open the `.env` file in `modules/auth/backend-example/`
2. Replace the content with:

```env
# SendGrid Configuration
SENDGRID_API_KEY=SG.your-api-key-here
FROM_EMAIL=your-verified-email@example.com

# Server Configuration
PORT=3000
```

3. Replace `SG.your-api-key-here` with the API key you copied in Step 2
4. Replace `your-verified-email@example.com` with the email you verified in Step 3

**Example:**
```env
SENDGRID_API_KEY=SG.abc123xyz789...
FROM_EMAIL=noreply@uniflow.app
PORT=3000
```

## Step 5: Install Dependencies

Open a terminal in the `backend-example` folder and run:

```bash
npm install
```

This will install `@sendgrid/mail` and other dependencies.

## Step 6: Start the Server

```bash
npm start
```

You should see:
```
🚀 Server running on port 3000
📊 Health check: http://localhost:3000/health
📧 Email Service: SendGrid
✅ SendGrid API key is configured
✅ From email: noreply@uniflow.app
✅ SendGrid is ready to send emails!
```

## Step 7: Test the Email Service

### Option A: Test via Health Check

Visit: `http://localhost:3000/health`

You should see:
```json
{
  "status": "ok",
  "service": "SendGrid",
  "configured": true,
  "fromEmail": "noreply@uniflow.app",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### Option B: Test via Flutter App

1. Run your Flutter app
2. Go to "Forgot Password?"
3. Enter your email address
4. Check your inbox for the verification code!

## Step 8: Deploy to Production (Optional)

For production, you'll want to deploy your backend to a cloud service:

### Railway (Recommended)

1. Sign up at [railway.app](https://railway.app/)
2. Create a new project → Deploy from GitHub
3. Select your repo and `modules/auth/backend-example` folder
4. Add environment variables:
   - `SENDGRID_API_KEY` = Your API key
   - `FROM_EMAIL` = Your verified email
   - `PORT` = 3000
5. Get your Railway URL (e.g., `https://uniflow-email.railway.app`)
6. Update `modules/auth/lib/services/email_config.dart`:
   ```dart
   static const String backendApiUrl = 'https://uniflow-email.railway.app';
   ```

### Other Options

- **Render**: Similar to Railway
- **Heroku**: Free tier discontinued, but still works
- **Google Cloud Run**: Good for Google Cloud users
- **AWS Lambda**: Serverless option

## Troubleshooting

### "API key not configured" error

- Make sure `SENDGRID_API_KEY` is set in your `.env` file
- Check that there are no extra spaces or quotes around the API key
- Restart your server after updating `.env`

### "FROM_EMAIL not configured" error

- Make sure `FROM_EMAIL` is set in your `.env` file
- The email must be verified in SendGrid (Step 3)

### "The from address does not match a verified Sender Identity" error

- The email in `FROM_EMAIL` must be verified in SendGrid
- Go to **Settings** → **Sender Authentication** and verify your sender
- Make sure you clicked the verification link in your email

### "Forbidden" or "401 Unauthorized" error

- Your API key might be invalid
- Generate a new API key in SendGrid
- Make sure you copied the entire key (starts with `SG.`)

### Emails not arriving

- Check your SendGrid **Activity** page to see if emails were sent
- Check spam/junk folder
- Make sure your SendGrid account is not suspended
- Verify you haven't exceeded the free tier limit (100 emails/day)

### "Rate limit exceeded" error

- Free tier allows 100 emails/day
- Wait 24 hours or upgrade to a paid plan
- Check your usage in SendGrid dashboard

## SendGrid Dashboard

You can monitor your email sending in the SendGrid dashboard:

- **Activity**: See all sent emails and their status
- **Stats**: View delivery rates and statistics
- **Settings** → **API Keys**: Manage your API keys
- **Settings** → **Sender Authentication**: Manage verified senders

## Next Steps

Once SendGrid is working:

1. ✅ Test the forgot password flow in your Flutter app
2. ✅ Verify emails are arriving in inboxes
3. ✅ Deploy backend to production (Railway, Render, etc.)
4. ✅ Update Flutter app to use production URL
5. ✅ Monitor email delivery in SendGrid dashboard

## Support

- SendGrid Documentation: [https://docs.sendgrid.com/](https://docs.sendgrid.com/)
- SendGrid Support: Available in dashboard
- Free tier includes email support

---

**That's it!** Your email service is now ready to send verification codes. 🎉

