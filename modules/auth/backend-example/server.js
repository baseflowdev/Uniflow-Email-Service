const express = require('express');
const sgMail = require('@sendgrid/mail');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

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

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'SendGrid',
    configured: !!process.env.SENDGRID_API_KEY,
    fromEmail: process.env.FROM_EMAIL || 'not set',
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
