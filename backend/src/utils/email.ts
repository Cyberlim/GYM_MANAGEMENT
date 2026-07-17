import nodemailer from 'nodemailer';

const getTransporter = () => {
  const emailUser = process.env.EMAIL_USER?.trim();
  const emailPass = process.env.EMAIL_PASS?.replace(/\s+/g, '') || process.env.SMTP_PASS || '2zQY6M8H2D8vU3yXwP';

  if (emailUser?.includes('@gmail.com')) {
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: emailUser,
        pass: emailPass,
      },
    });
  }

  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.ethereal.email',
    port: parseInt(process.env.SMTP_PORT || '587'),
    auth: {
      user: process.env.EMAIL_USER || process.env.SMTP_USER || 'bernadette.gislason@ethereal.email',
      pass: emailPass,
    },
  });
};

const sendEmail = async (mailOptions: any) => {
  const transporter = getTransporter();
  const info = await transporter.sendMail(mailOptions);
  console.log('Message sent: %s', info.messageId);
  if (process.env.SMTP_HOST === undefined || process.env.SMTP_HOST === 'smtp.ethereal.email') {
    console.log('Preview URL: %s', nodemailer.getTestMessageUrl(info));
  }
};

export const sendOTP = async (email: string, otp: string) => {
  await sendEmail({
    from: '"Gym Management" <noreply@gymmanagement.com>',
    to: email,
    subject: 'Your 2FA Login Code',
    text: `Your login code is: ${otp}. It will expire in 10 minutes.`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #333;">Your Two-Factor Authentication Code</h2>
        <p>Please use the following 6-digit code to complete your login.</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #4CAF50; padding: 16px 0;">${otp}</div>
        <p style="color: #777; font-size: 14px;">This code will expire in 10 minutes. If you didn't request this, you can safely ignore this email.</p>
      </div>
    `,
  });
};

export const sendVerificationEmail = async (email: string, code: string) => {
  await sendEmail({
    from: '"Gym Management" <noreply@gymmanagement.com>',
    to: email,
    subject: 'Verify Your Email Address',
    text: `Your verification code is: ${code}. It will expire in 10 minutes.`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #333;">Welcome to Gym Management!</h2>
        <p>Please use the following 6-digit code to verify your email address and complete your registration.</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #4CAF50; padding: 16px 0;">${code}</div>
        <p style="color: #777; font-size: 14px;">This code will expire in 10 minutes.</p>
      </div>
    `,
  });
};

export const sendWelcomeEmail = async (email: string, name: string) => {
  await sendEmail({
    from: '"Gym Management" <noreply@gymmanagement.com>',
    to: email,
    subject: 'Welcome to Gym Management!',
    text: `Welcome ${name}! Your account has been successfully verified.`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #333;">Welcome ${name}!</h2>
        <p>Your account has been successfully verified.</p>
        <p>You can now log in and set up your gym to start managing your members, staff, and classes.</p>
      </div>
    `,
  });
};

export const sendPasswordResetEmail = async (email: string, code: string) => {
  await sendEmail({
    from: '"Gym Management" <noreply@gymmanagement.com>',
    to: email,
    subject: 'Password Reset Request',
    text: `Your password reset code is: ${code}. It will expire in 15 minutes.`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #333;">Password Reset Request</h2>
        <p>You recently requested to reset your password. Use the following 6-digit code to proceed.</p>
        <div style="font-size: 32px; font-weight: bold; letter-spacing: 4px; color: #4CAF50; padding: 16px 0;">${code}</div>
        <p style="color: #777; font-size: 14px;">This code will expire in 15 minutes. If you did not request a password reset, please ignore this email.</p>
      </div>
    `,
  });
};

export const sendNotificationEmail = async (email: string, subject: string, message: string) => {
  await sendEmail({
    from: '"Gym Management" <noreply@gymmanagement.com>',
    to: email,
    subject: subject,
    text: message,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #333;">${subject}</h2>
        <p>${message}</p>
      </div>
    `,
  });
};

export const sendSuspensionEmail = async (email: string, name: string, suspensionId: string) => {
  await sendEmail({
    from: '"Gym Management" <noreply@gymmanagement.com>',
    to: email,
    subject: 'Action Required: Account Suspended',
    text: `Hello ${name}, your account has been suspended. Please contact support using this Unique ID: ${suspensionId}`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #d32f2f;">Account Suspended</h2>
        <p>Hello ${name},</p>
        <p>Your gym owner account has been suspended due to a violation of our terms of service or an unresolved issue.</p>
        <p>To resolve this issue, please log into your account to access the Support portal, and provide the following Unique Suspension ID:</p>
        <div style="background-color: #f5f5f5; padding: 12px; font-family: monospace; font-size: 16px; margin: 16px 0; text-align: center; border: 1px dashed #ccc;">
          ${suspensionId}
        </div>
        <p>Our Superadmin team will assist you in restoring your account.</p>
      </div>
    `,
  });
};

export const sendReactivationEmail = async (email: string, name: string) => {
  await sendEmail({
    from: '"Gym Management" <noreply@gymmanagement.com>',
    to: email,
    subject: 'Your Account Has Been Reactivated!',
    text: `Hello ${name}, good news! Your gym owner account has been reactivated. You can now log in normally.`,
    html: `
      <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;">
        <h2 style="color: #4CAF50;">Account Reactivated</h2>
        <p>Hello ${name},</p>
        <p>Good news! Your gym owner account has been successfully reactivated by the Superadmin team.</p>
        <p>You can now log into your account and resume managing your gym operations.</p>
        <p>Thank you for your patience!</p>
      </div>
    `,
  });
};
