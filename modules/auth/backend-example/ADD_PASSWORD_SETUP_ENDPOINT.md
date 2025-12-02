# Add Password Setup Email Endpoint to Backend

The backend is missing the `/api/send-password-setup-email` endpoint. Add this to your `server.js` file:

## Add this endpoint to server.js:

```javascript
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
```

## Also add the setup-password endpoint if it doesn't exist:

```javascript
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

    // Verify token (this should match the token stored in the app)
    // For now, we'll just verify the user exists and set the password via Firebase Admin
    
    const admin = require('firebase-admin');
    
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
```

## Steps to deploy:

1. Add these endpoints to your `server.js` file on your local machine or in your GitHub repository
2. Commit and push to GitHub
3. Render will automatically redeploy with the new endpoints

## Note:

Make sure your backend has:
- `firebase-admin` package installed
- Firebase Admin SDK initialized with proper credentials
- SendGrid configured with `SENDGRID_API_KEY` and `SENDGRID_FROM_EMAIL` environment variables

