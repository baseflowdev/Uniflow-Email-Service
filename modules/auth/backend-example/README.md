# UniFlow Email Service Backend

Backend API for sending verification emails via Gmail API.

## Setup

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Configure Google Cloud Console:**
   - Follow the guide in `../GMAIL_API_SETUP.md`
   - Get your OAuth credentials or Service Account key

3. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials
   ```

4. **Run the server:**
   ```bash
   npm start
   # Or for development with auto-reload:
   npm run dev
   ```

5. **Authorize (if using OAuth):**
   - Visit `http://localhost:3000/auth`
   - Authorize with your Google account
   - The refresh token will be saved

6. **Test:**
   ```bash
   curl -X POST http://localhost:3000/api/send-verification-email \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","code":"123456"}'
   ```

## Deployment

Deploy to any Node.js hosting service:
- Heroku
- Railway
- Render
- Google Cloud Run
- Vercel
- etc.

Make sure to set environment variables in your hosting platform.



