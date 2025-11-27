# Deploy Backend to Cloud (Production)

For production, deploy your backend to a cloud service so it's always accessible.

## Option A: Railway (Recommended - Easy & Free Tier)

1. **Sign up**: Go to https://railway.app/ and sign up with GitHub
2. **Create New Project**: Click "New Project"
3. **Deploy from GitHub**: 
   - Select "Deploy from GitHub repo"
   - Choose your repository
   - Select the `modules/auth/backend-example` folder
4. **Add Environment Variables**:
   - Go to your project → Variables
   - Add:
     ```
     GOOGLE_CLIENT_ID=your-client-id
     GOOGLE_CLIENT_SECRET=your-client-secret
     REDIRECT_URI=https://your-app.railway.app/auth/callback
     PORT=3000
     ```
5. **Get Your URL**: Railway will give you a URL like `https://your-app.railway.app`
6. **Update Google Cloud Console**:
   - Add `https://your-app.railway.app/auth/callback` to Authorized redirect URIs
7. **Update Flutter App**:
   - Update `email_config.dart` with your Railway URL

## Option B: Render (Free Tier Available)

1. **Sign up**: Go to https://render.com/
2. **Create New Web Service**
3. **Connect GitHub** and select your repo
4. **Configure**:
   - **Root Directory**: `modules/auth/backend-example`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
5. **Add Environment Variables** (same as Railway)
6. **Deploy** and get your URL

## Option C: Heroku (Paid, but reliable)

1. **Install Heroku CLI**: https://devcenter.heroku.com/articles/heroku-cli
2. **Login**: `heroku login`
3. **Create App**: `heroku create your-app-name`
4. **Set Environment Variables**:
   ```bash
   heroku config:set GOOGLE_CLIENT_ID=your-id
   heroku config:set GOOGLE_CLIENT_SECRET=your-secret
   heroku config:set REDIRECT_URI=https://your-app.herokuapp.com/auth/callback
   ```
5. **Deploy**: `git push heroku main`
6. **Get URL**: Your app will be at `https://your-app-name.herokuapp.com`

## Option D: Google Cloud Run (Free Tier)

1. **Install Google Cloud SDK**
2. **Create Dockerfile** in `backend-example`:
   ```dockerfile
   FROM node:18
   WORKDIR /app
   COPY package*.json ./
   RUN npm install
   COPY . .
   EXPOSE 3000
   CMD ["npm", "start"]
   ```
3. **Deploy**:
   ```bash
   gcloud run deploy uniflow-email-service \
     --source . \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated
   ```

## After Deployment

1. **Update Google Cloud Console**:
   - Add your production URL to Authorized redirect URIs
   - Example: `https://your-app.railway.app/auth/callback`

2. **Update Flutter App**:
   - Update `modules/auth/lib/services/email_config.dart`:
     ```dart
     static const String backendApiUrl = 'https://your-app.railway.app';
     ```

3. **Re-authorize Gmail API**:
   - Visit: `https://your-app.railway.app/auth`
   - Sign in and authorize

4. **Test**:
   - Your Flutter app can now access the backend from anywhere!

## Important Notes

- **HTTPS Required**: All cloud services provide HTTPS automatically
- **Environment Variables**: Never commit `.env` file to git
- **Refresh Token**: The refresh token will be stored in the cloud service's environment
- **Scaling**: Cloud services handle scaling automatically

## Recommended for Your Use Case

**For Development/Testing**: Use **ngrok** (see NGROK_SETUP.md)
**For Production**: Use **Railway** or **Render** (both have free tiers)


