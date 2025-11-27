# Quick Setup Instructions

This backend now uses **SendGrid** for sending emails. It's much simpler than Gmail API!

## 📚 Full Setup Guide

For detailed instructions, see **[SENDGRID_SETUP.md](./SENDGRID_SETUP.md)**

## Quick Start

### Step 1: Install Dependencies

```bash
npm install
```

### Step 2: Set Up SendGrid

1. Sign up at [sendgrid.com](https://sendgrid.com) (free account)
2. Get your API key from **Settings** → **API Keys**
3. Verify a sender email in **Settings** → **Sender Authentication**

### Step 3: Create .env File

Create a `.env` file in the `backend-example` folder:

```env
# SendGrid Configuration
SENDGRID_API_KEY=SG.your-api-key-here
FROM_EMAIL=your-verified-email@example.com

# Server Configuration
PORT=3000
```

### Step 4: Start the Server

```bash
npm start
```

You should see:
```
🚀 Server running on port 3000
✅ SendGrid is ready to send emails!
```

### Step 5: Test

1. Visit `http://localhost:3000/health` to verify setup
2. Test in your Flutter app - go to "Forgot Password?" and enter your email
3. Check your inbox for the verification code!

## Need Help?

See **[SENDGRID_SETUP.md](./SENDGRID_SETUP.md)** for:
- Detailed SendGrid account setup
- Step-by-step API key creation
- Sender email verification
- Troubleshooting guide
- Production deployment options



