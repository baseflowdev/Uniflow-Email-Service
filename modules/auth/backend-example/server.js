const express = require('express');
const cors = require('cors');
const sgMail = require('@sendgrid/mail');
const admin = require('firebase-admin');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize SendGrid
if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
}

// Initialize Firebase Admin SDK
let firebaseAdminInitialized = false;

// Async function to initialize and verify Firebase Admin SDK
async function initializeFirebaseAdmin() {
  if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
    try {
      // Handle private key formatting - Render environment variables may have escaped newlines
      let privateKey = process.env.FIREBASE_PRIVATE_KEY;
      
      // Remove any surrounding quotes that might have been added
      privateKey = privateKey.trim();
      if (privateKey.startsWith('"') && privateKey.endsWith('"')) {
        privateKey = privateKey.slice(1, -1);
      }
      if (privateKey.startsWith("'") && privateKey.endsWith("'")) {
        privateKey = privateKey.slice(1, -1);
      }
      
      // Replace escaped newlines with actual newlines (handles both \n and \\n)
      privateKey = privateKey.replace(/\\n/g, '\n');
      
      // If the key is stored as a single line without newlines, try to format it
      // Firebase private keys are typically in PKCS#8 format
      if (!privateKey.includes('\n') && privateKey.length > 100) {
        // Key might be stored as a single line, try to add newlines every 64 characters
        // But first check if it has markers
        if (privateKey.includes('BEGIN') && privateKey.includes('END')) {
          // Has markers but no newlines - add them
          privateKey = privateKey
            .replace(/-----BEGIN PRIVATE KEY-----/, '-----BEGIN PRIVATE KEY-----\n')
            .replace(/-----END PRIVATE KEY-----/, '\n-----END PRIVATE KEY-----')
            .replace(/(.{64})/g, '$1\n')
            .replace(/\n\n/g, '\n');
        }
      }
      
      // Validate key has proper format
      if (!privateKey.includes('BEGIN') || !privateKey.includes('END')) {
        throw new Error('Invalid private key format: missing BEGIN/END markers. Please ensure FIREBASE_PRIVATE_KEY includes the full key with markers.');
      }
      
      // Validate key is not empty
      if (privateKey.trim().length < 100) {
        throw new Error('Invalid private key: key appears to be too short or empty');
      }
      
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId: process.env.FIREBASE_PROJECT_ID,
          privateKey: privateKey,
          clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        }),
      });
      
      // Actually test the credential by trying to get an access token
      // This will fail immediately if the key is invalid
      try {
        const app = admin.app();
        // Force credential validation by attempting to get access token
        const credential = app.options.credential;
        if (credential && credential.getAccessToken) {
          // This will throw if the key is invalid
          await credential.getAccessToken();
        }
        firebaseAdminInitialized = true;
        console.log('✅ Firebase Admin SDK initialized and credential verified');
      } catch (verifyError) {
        console.error('❌ Firebase credential verification failed:', verifyError.message);
        console.error('❌ This means the private key is invalid or malformed');
        console.error('❌ Private key preview (first 100 chars):', privateKey.substring(0, 100));
        console.error('❌ Private key has BEGIN marker:', privateKey.includes('BEGIN'));
        console.error('❌ Private key has END marker:', privateKey.includes('END'));
        console.error('❌ Private key length:', privateKey.length);
        throw new Error(`Firebase credential invalid: ${verifyError.message}. Please check FIREBASE_PRIVATE_KEY format.`);
      }
    } catch (error) {
      console.error('❌ Firebase Admin SDK initialization failed:', error.message);
      console.error('❌ Error stack:', error.stack);
      console.error('❌ Environment check:', {
        hasProjectId: !!process.env.FIREBASE_PROJECT_ID,
        hasPrivateKey: !!process.env.FIREBASE_PRIVATE_KEY,
        privateKeyLength: process.env.FIREBASE_PRIVATE_KEY ? process.env.FIREBASE_PRIVATE_KEY.length : 0,
        privateKeyPreview: process.env.FIREBASE_PRIVATE_KEY ? process.env.FIREBASE_PRIVATE_KEY.substring(0, 50) + '...' : 'missing',
        hasClientEmail: !!process.env.FIREBASE_CLIENT_EMAIL,
      });
      firebaseAdminInitialized = false;
    }
  } else {
    console.warn('⚠️ Firebase Admin SDK not initialized - missing environment variables');
    console.warn('⚠️ Missing:', {
      FIREBASE_PROJECT_ID: !process.env.FIREBASE_PROJECT_ID,
      FIREBASE_PRIVATE_KEY: !process.env.FIREBASE_PRIVATE_KEY,
      FIREBASE_CLIENT_EMAIL: !process.env.FIREBASE_CLIENT_EMAIL,
    });
    firebaseAdminInitialized = false;
  }
}

// Initialize Firebase Admin SDK (async)
initializeFirebaseAdmin().catch(err => {
  console.error('❌ Failed to initialize Firebase Admin SDK:', err);
});

// Initialize MongoDB
let mongoClient;
let db;
if (process.env.MONGODB_URI) {
  try {
    mongoClient = new MongoClient(process.env.MONGODB_URI);
    mongoClient.connect().then(() => {
      db = mongoClient.db('uniflow');
      console.log('✅ MongoDB connected');
    }).catch(err => {
      console.error('❌ MongoDB connection failed:', err.message);
    });
  } catch (error) {
    console.error('❌ MongoDB initialization failed:', error.message);
  }
} else {
  console.warn('⚠️ MongoDB not initialized - missing MONGODB_URI');
}

// Middleware to verify Firebase token
async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      error: 'No authorization token provided'
    });
  }

  const token = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Token verification failed:', error.message);
    return res.status(401).json({
      success: false,
      error: 'Invalid or expired token'
    });
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    firebase: !!admin.apps.length,
    mongodb: !!db,
    sendgrid: !!process.env.SENDGRID_API_KEY
  });
});

// POST /api/send-verification-email
app.post('/api/send-verification-email', async (req, res) => {
  try {
    const { email, code } = req.body;

    if (!email || !code) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: email, code'
      });
    }

    if (!process.env.SENDGRID_API_KEY) {
      return res.status(500).json({
        success: false,
        error: 'SendGrid not configured'
      });
    }

    const msg = {
      to: email,
      from: process.env.SENDGRID_FROM_EMAIL || 'baseflowdev@gmail.com',
      subject: 'Your UniFlow Verification Code',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }
            .code { font-size: 32px; font-weight: bold; text-align: center; color: #4CAF50; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Verify Your Email</h1>
            </div>
            <div class="content">
              <p>Hello,</p>
              <p>Your verification code is:</p>
              <div class="code">${code}</div>
              <p>This code will expire in 10 minutes.</p>
              <p>If you didn't request this code, you can safely ignore this email.</p>
            </div>
            <div class="footer">
              <p>UniFlow - Your Academic Companion</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `Your UniFlow verification code is: ${code}\n\nThis code will expire in 10 minutes.\n\nIf you didn't request this code, you can safely ignore this email.`
    };

    await sgMail.send(msg);

    res.json({
      success: true,
      message: 'Verification email sent successfully'
    });
  } catch (error) {
    console.error('Error sending verification email:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send verification email',
      details: error.message
    });
  }
});

// POST /api/send-password-setup-email
// Sends password setup email for Google-only accounts
app.post('/api/send-password-setup-email', async (req, res) => {
  try {
    const { email, token, setupUrl } = req.body;

    if (!email || !token || !setupUrl) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: email, token, setupUrl'
      });
    }

    if (!process.env.SENDGRID_API_KEY) {
      return res.status(500).json({
        success: false,
        error: 'SendGrid not configured'
      });
    }

    // Send password setup email via SendGrid
    const msg = {
      to: email,
      from: process.env.SENDGRID_FROM_EMAIL || 'baseflowdev@gmail.com',
      subject: 'Set Up Your Password - UniFlow',
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 5px 5px 0 0; }
            .content { background-color: #f9f9f9; padding: 30px; border-radius: 0 0 5px 5px; }
            .button { display: inline-block; padding: 12px 30px; background-color: #4CAF50; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>Set Up Your Password</h1>
            </div>
            <div class="content">
              <p>Hello,</p>
              <p>You requested to set up a password for your UniFlow account. Click the button below to set your password:</p>
              <p style="text-align: center;">
                <a href="${setupUrl}" class="button">Set Up Password</a>
              </p>
              <p>Or copy and paste this link into your browser:</p>
              <p style="word-break: break-all; color: #666;">${setupUrl}</p>
              <p><strong>This link will expire in 24 hours.</strong></p>
              <p>If you didn't request this, you can safely ignore this email.</p>
            </div>
            <div class="footer">
              <p>UniFlow - Your Academic Companion</p>
            </div>
          </div>
        </body>
        </html>
      `,
      text: `
        Set Up Your Password - UniFlow
        
        Hello,
        
        You requested to set up a password for your UniFlow account. 
        Click the link below to set your password:
        
        ${setupUrl}
        
        This link will expire in 24 hours.
        
        If you didn't request this, you can safely ignore this email.
        
        UniFlow - Your Academic Companion
      `
    };

    await sgMail.send(msg);

    res.json({
      success: true,
      message: 'Password setup email sent successfully'
    });
  } catch (error) {
    console.error('Error sending password setup email:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to send password setup email',
      details: error.message
    });
  }
});

// GET /api/setup-password
// Serves HTML form for password setup
app.get('/api/setup-password', (req, res) => {
  const { token, email } = req.query;
  
  if (!token || !email) {
    return res.status(400).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Invalid Link - UniFlow</title>
        <style>
          body { font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f5f5f5; }
          .container { background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center; max-width: 500px; }
          h1 { color: #d32f2f; margin-bottom: 20px; }
          p { color: #666; line-height: 1.6; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Invalid Link</h1>
          <p>This password setup link is invalid or missing required parameters.</p>
          <p>Please request a new password setup link from the app.</p>
        </div>
      </body>
      </html>
    `);
  }

  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Set Up Your Password - UniFlow</title>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        * { box-sizing: border-box; }
        body { 
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
          display: flex; 
          justify-content: center; 
          align-items: center; 
          min-height: 100vh; 
          margin: 0; 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          padding: 20px;
        }
        .container { 
          background: white; 
          padding: 40px; 
          border-radius: 12px; 
          box-shadow: 0 10px 40px rgba(0,0,0,0.2); 
          max-width: 500px; 
          width: 100%;
        }
        h1 { 
          color: #333; 
          margin-bottom: 10px; 
          font-size: 28px;
        }
        .subtitle {
          color: #666;
          margin-bottom: 30px;
          font-size: 14px;
        }
        .form-group {
          margin-bottom: 20px;
        }
        label {
          display: block;
          margin-bottom: 8px;
          color: #333;
          font-weight: 500;
          font-size: 14px;
        }
        input {
          width: 100%;
          padding: 12px;
          border: 2px solid #e0e0e0;
          border-radius: 8px;
          font-size: 16px;
          transition: border-color 0.3s;
        }
        input:focus {
          outline: none;
          border-color: #667eea;
        }
        .error {
          color: #d32f2f;
          font-size: 14px;
          margin-top: 8px;
          display: none;
        }
        .error.show {
          display: block;
        }
        .success {
          color: #4caf50;
          font-size: 14px;
          margin-top: 8px;
          display: none;
        }
        .success.show {
          display: block;
        }
        button {
          width: 100%;
          padding: 14px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border: none;
          border-radius: 8px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          transition: transform 0.2s, box-shadow 0.2s;
          margin-top: 10px;
        }
        button:hover {
          transform: translateY(-2px);
          box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        button:active {
          transform: translateY(0);
        }
        button:disabled {
          opacity: 0.6;
          cursor: not-allowed;
          transform: none;
        }
        .loading {
          display: none;
          text-align: center;
          margin-top: 20px;
        }
        .loading.show {
          display: block;
        }
        .spinner {
          border: 3px solid #f3f3f3;
          border-top: 3px solid #667eea;
          border-radius: 50%;
          width: 30px;
          height: 30px;
          animation: spin 1s linear infinite;
          margin: 0 auto;
        }
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Set Up Your Password</h1>
        <p class="subtitle">Enter a new password for your UniFlow account</p>
        <form id="passwordForm">
          <div class="form-group">
            <label for="password">New Password</label>
            <input type="password" id="password" name="password" required minlength="6" placeholder="Enter your new password">
            <div class="error" id="passwordError"></div>
          </div>
          <div class="form-group">
            <label for="confirmPassword">Confirm Password</label>
            <input type="password" id="confirmPassword" name="confirmPassword" required minlength="6" placeholder="Confirm your new password">
            <div class="error" id="confirmError"></div>
          </div>
          <button type="submit" id="submitBtn">Set Password</button>
          <div class="success" id="successMsg"></div>
          <div class="error" id="errorMsg"></div>
          <div class="loading" id="loading">
            <div class="spinner"></div>
            <p style="margin-top: 10px; color: #666;">Setting up your password...</p>
          </div>
        </form>
      </div>
      <script>
        const form = document.getElementById('passwordForm');
        const passwordInput = document.getElementById('password');
        const confirmInput = document.getElementById('confirmPassword');
        const passwordError = document.getElementById('passwordError');
        const confirmError = document.getElementById('confirmError');
        const errorMsg = document.getElementById('errorMsg');
        const successMsg = document.getElementById('successMsg');
        const loading = document.getElementById('loading');
        const submitBtn = document.getElementById('submitBtn');
        
        const token = '${token}';
        const email = '${email}';
        // Use full backend URL - get it from current origin
        const backendUrl = window.location.origin;
        
        form.addEventListener('submit', async (e) => {
          e.preventDefault();
          
          // Clear previous errors
          passwordError.classList.remove('show');
          confirmError.classList.remove('show');
          errorMsg.classList.remove('show');
          successMsg.classList.remove('show');
          
          const password = passwordInput.value;
          const confirmPassword = confirmInput.value;
          
          // Validate password length
          if (password.length < 6) {
            passwordError.textContent = 'Password must be at least 6 characters';
            passwordError.classList.add('show');
            return;
          }
          
          // Validate passwords match
          if (password !== confirmPassword) {
            confirmError.textContent = 'Passwords do not match';
            confirmError.classList.add('show');
            return;
          }
          
          // Show loading state
          submitBtn.disabled = true;
          loading.classList.add('show');
          
          try {
            const response = await fetch(backendUrl + '/api/setup-password', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                email: email,
                password: password,
                token: token
              })
            });
            
            const data = await response.json();
            
            if (response.ok && data.success) {
              successMsg.textContent = data.message || 'Password set successfully! You can now sign in with email and password.';
              successMsg.classList.add('show');
              form.style.display = 'none';
              submitBtn.style.display = 'none';
            } else {
              errorMsg.textContent = data.error || data.details || 'Failed to set password. Please try again.';
              errorMsg.classList.add('show');
            }
          } catch (error) {
            console.error('Error setting password:', error);
            errorMsg.textContent = 'An error occurred: ' + error.message + '. Please try again later.';
            errorMsg.classList.add('show');
          } finally {
            submitBtn.disabled = false;
            loading.classList.remove('show');
          }
        });
      </script>
    </body>
    </html>
  `);
});

// POST /api/setup-password
// Sets password for Google-only account using token
app.post('/api/setup-password', async (req, res) => {
  try {
    console.log('🔵 Password setup request received');
    const { email, password, token } = req.body;
    console.log('🔵 Request body:', { email: email ? 'present' : 'missing', password: password ? 'present' : 'missing', token: token ? 'present' : 'missing' });

    if (!email || !password || !token) {
      console.log('❌ Missing required fields');
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: email, password, token'
      });
    }

    if (!admin.apps.length || !firebaseAdminInitialized) {
      console.log('❌ Firebase Admin SDK not initialized or not verified');
      return res.status(500).json({
        success: false,
        error: 'Firebase Admin SDK not properly initialized. Please check server logs and environment variables.'
      });
    }

    // Get user by email
    let userRecord;
    try {
      console.log('🔵 Looking up user by email:', email.toLowerCase());
      userRecord = await admin.auth().getUserByEmail(email.toLowerCase());
      console.log('✅ User found:', userRecord.uid);
    } catch (error) {
      console.error('❌ Error looking up user:', error.code, error.message);
      if (error.code === 'auth/user-not-found') {
        return res.status(404).json({
          success: false,
          error: 'No account found with this email'
        });
      }
      throw error;
    }

    // Check if user already has a password
    const providers = userRecord.providerData.map(p => p.providerId);
    console.log('🔵 User providers:', providers);
    if (providers.includes('password')) {
      console.log('⚠️ User already has password provider');
      return res.status(400).json({
        success: false,
        error: 'This account already has a password set'
      });
    }

    // Note: Token verification should be done by the client app
    // The client app stores the token locally and verifies it before calling this endpoint
    // For security, you might want to add token verification here as well

    // Update user password using Firebase Admin SDK
    console.log('🔵 Setting password for user:', userRecord.uid);
    await admin.auth().updateUser(userRecord.uid, {
      password: password
    });
    console.log('✅ Password set successfully');

    res.json({
      success: true,
      message: 'Password set successfully. You can now sign in with email and password.'
    });
  } catch (error) {
    console.error('❌ Error setting password:', error);
    console.error('❌ Error stack:', error.stack);
    res.status(500).json({
      success: false,
      error: 'Failed to set password',
      details: error.message
    });
  }
});

// POST /api/users
// Create or update user profile
app.post('/api/users', verifyFirebaseToken, async (req, res) => {
  try {
    if (!db) {
      return res.status(500).json({
        success: false,
        error: 'Database not connected'
      });
    }

    const userId = req.user.uid;
    const userData = {
      ...req.body,
      id: userId,
      updatedAt: new Date()
    };

    // Upsert user profile
    await db.collection('users').updateOne(
      { id: userId },
      { 
        $set: userData,
        $setOnInsert: { createdAt: new Date() }
      },
      { upsert: true }
    );

    res.json({
      success: true,
      user: userData
    });
  } catch (error) {
    console.error('Error saving user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to save user',
      details: error.message
    });
  }
});

// GET /api/users/me
// Get current user profile
app.get('/api/users/me', verifyFirebaseToken, async (req, res) => {
  try {
    if (!db) {
      return res.status(500).json({
        success: false,
        error: 'Database not connected'
      });
    }

    const userId = req.user.uid;
    const user = await db.collection('users').findOne({ id: userId });

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      user: user
    });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user',
      details: error.message
    });
  }
});

// PUT /api/users/me
// Update current user profile
app.put('/api/users/me', verifyFirebaseToken, async (req, res) => {
  try {
    if (!db) {
      return res.status(500).json({
        success: false,
        error: 'Database not connected'
      });
    }

    const userId = req.user.uid;
    const updateData = {
      ...req.body,
      updatedAt: new Date()
    };

    const result = await db.collection('users').updateOne(
      { id: userId },
      { $set: updateData }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    const updatedUser = await db.collection('users').findOne({ id: userId });

    res.json({
      success: true,
      user: updatedUser
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update user',
      details: error.message
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});



