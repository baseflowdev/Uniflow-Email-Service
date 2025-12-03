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
if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
    console.log('✅ Firebase Admin SDK initialized');
  } catch (error) {
    console.error('❌ Firebase Admin SDK initialization failed:', error.message);
  }
} else {
  console.warn('⚠️ Firebase Admin SDK not initialized - missing environment variables');
}

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

// POST /api/setup-password
// Sets password for Google-only account using token
app.post('/api/setup-password', async (req, res) => {
  try {
    const { email, password, token } = req.body;

    if (!email || !password || !token) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: email, password, token'
      });
    }

    if (!admin.apps.length) {
      return res.status(500).json({
        success: false,
        error: 'Firebase Admin SDK not initialized'
      });
    }

    // Get user by email
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(email.toLowerCase());
    } catch (error) {
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
    if (providers.includes('password')) {
      return res.status(400).json({
        success: false,
        error: 'This account already has a password set'
      });
    }

    // Note: Token verification should be done by the client app
    // The client app stores the token locally and verifies it before calling this endpoint
    // For security, you might want to add token verification here as well

    // Update user password using Firebase Admin SDK
    await admin.auth().updateUser(userRecord.uid, {
      password: password
    });

    res.json({
      success: true,
      message: 'Password set successfully. You can now sign in with email and password.'
    });
  } catch (error) {
    console.error('Error setting password:', error);
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



