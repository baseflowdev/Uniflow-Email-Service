const express = require('express');
const sgMail = require('@sendgrid/mail');
const cors = require('cors');
const admin = require('firebase-admin');
const { MongoClient } = require('mongodb');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
let firebaseAdminInitialized = false;
if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_PRIVATE_KEY && process.env.FIREBASE_CLIENT_EMAIL) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
    firebaseAdminInitialized = true;
    console.log('✅ Firebase Admin initialized successfully');
  } catch (error) {
    console.log('⚠️  Firebase Admin initialization failed:', error.message);
  }
} else {
  console.log('⚠️  Firebase Admin credentials not found in environment variables');
}

// Initialize MongoDB
let mongoClient = null;
let usersCollection = null;
if (process.env.MONGODB_URI) {
  mongoClient = new MongoClient(process.env.MONGODB_URI);
  (async () => {
    try {
      await mongoClient.connect();
      const db = mongoClient.db('uniflow');
      usersCollection = db.collection('users');
      console.log('✅ MongoDB connected successfully');
    } catch (error) {
      console.log('⚠️  MongoDB connection failed:', error.message);
    }
  })();
} else {
  console.log('⚠️  MONGODB_URI not found in environment variables');
}

// Middleware to verify Firebase ID token
async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ success: false, error: 'No authorization token provided' });
  }

  const token = authHeader.split('Bearer ')[1];
  
  if (!firebaseAdminInitialized) {
    return res.status(500).json({ success: false, error: 'Firebase Admin not initialized' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.status(401).json({ success: false, error: 'Invalid or expired token' });
  }
}

// Initialize SendGrid
if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
  console.log('✅ SendGrid initialized successfully');
} else {
  console.log('⚠️  SENDGRID_API_KEY not found in environment variables');
}

// Send verification email endpoint
app.post('/api/send-verification-email', async (req, res) => {
  try {
    const { email, code, subject, message } = req.body;

    if (!process.env.SENDGRID_API_KEY) {
      return res.status(500).json({ 
        success: false, 
        error: 'SendGrid API key not configured. Please set SENDGRID_API_KEY in your .env file.' 
      });
    }

    if (!process.env.FROM_EMAIL) {
      return res.status(500).json({ 
        success: false, 
        error: 'FROM_EMAIL not configured. Please set FROM_EMAIL in your .env file (must be verified in SendGrid).' 
      });
    }

    // Create email content
    const emailContent = message || `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #333;">Password Reset Verification</h2>
        <p>Your verification code is:</p>
        <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #0066cc; text-align: center; padding: 20px; background-color: #f5f5f5; border-radius: 8px;">
          ${code}
        </p>
        <p>This code expires in 10 minutes.</p>
        <p style="color: #666; font-size: 14px;">If you didn't request this, please ignore this email.</p>
      </div>
    `;

    // Send email via SendGrid
    const msg = {
      to: email,
      from: process.env.FROM_EMAIL,
      subject: subject || 'UniFlow - Password Reset Verification Code',
      html: emailContent,
    };

    await sgMail.send(msg);
    
    console.log('✅ Email sent successfully to:', email);
    res.json({ success: true, message: 'Email sent successfully' });
  } catch (error) {
    console.error('❌ Error sending email:', error);
    
    // Provide helpful error messages
    let errorMessage = error.message;
    if (error.response) {
      const body = error.response.body;
      if (body && body.errors) {
        errorMessage = body.errors.map(e => e.message).join(', ');
      }
    }
    
    res.status(500).json({ 
      success: false, 
      error: errorMessage,
      details: error.response?.body 
    });
  }
});

// User profile endpoints
// Create or update user profile
app.post('/api/users', verifyFirebaseToken, async (req, res) => {
  try {
    if (!usersCollection) {
      return res.status(500).json({ success: false, error: 'Database not configured' });
    }

    const userId = req.user.uid;
    const userData = {
      ...req.body,
      id: userId,
      updatedAt: new Date(),
    };

    // Upsert user profile
    await usersCollection.updateOne(
      { id: userId },
      { $set: userData },
      { upsert: true }
    );

    res.json({ success: true, user: userData });
  } catch (error) {
    console.error('Error saving user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get current user profile
app.get('/api/users/me', verifyFirebaseToken, async (req, res) => {
  try {
    if (!usersCollection) {
      return res.status(500).json({ success: false, error: 'Database not configured' });
    }

    const userId = req.user.uid;
    const user = await usersCollection.findOne({ id: userId });

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({ success: true, user });
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Update user profile
app.put('/api/users/me', verifyFirebaseToken, async (req, res) => {
  try {
    if (!usersCollection) {
      return res.status(500).json({ success: false, error: 'Database not configured' });
    }

    const userId = req.user.uid;
    const updateData = {
      ...req.body,
      id: userId,
      updatedAt: new Date(),
    };

    const result = await usersCollection.updateOne(
      { id: userId },
      { $set: updateData }
    );

    if (result.matchedCount === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const updatedUser = await usersCollection.findOne({ id: userId });
    res.json({ success: true, user: updatedUser });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'UniFlow Backend',
    sendgrid: {
      configured: !!process.env.SENDGRID_API_KEY,
      fromEmail: process.env.FROM_EMAIL || 'not set',
    },
    firebase: {
      configured: firebaseAdminInitialized,
    },
    mongodb: {
      configured: !!process.env.MONGODB_URI,
      connected: usersCollection !== null,
    },
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`\n🚀 Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`\n📧 Email Service: SendGrid`);
  
  if (process.env.SENDGRID_API_KEY) {
    console.log(`✅ SendGrid API key is configured`);
  } else {
    console.log(`⚠️  SENDGRID_API_KEY not found in .env file`);
  }
  
  if (process.env.FROM_EMAIL) {
    console.log(`✅ From email: ${process.env.FROM_EMAIL}`);
  } else {
    console.log(`⚠️  FROM_EMAIL not set in .env file`);
  }
  
  if (process.env.SENDGRID_API_KEY && process.env.FROM_EMAIL) {
    console.log(`\n✅ SendGrid is ready to send emails!`);
  } else {
    console.log(`\n⚠️  Please configure SENDGRID_API_KEY and FROM_EMAIL in your .env file`);
    console.log(`   See SENDGRID_SETUP.md for instructions`);
  }
});
