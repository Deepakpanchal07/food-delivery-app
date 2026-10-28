
const nodemailer = require("nodemailer");
require("dotenv").config();

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS?.replace(/\s/g, ""),
  },
});

async function verifyEmailConnection() {
  try {
    await transporter.verify();

    console.log("✅ Gmail SMTP connection successful");
    return true;
  } catch (error) {
    console.error("❌ Gmail SMTP connection failed:", error.message);
    return false;
  }
}

async function sendTestEmail(to) {
  await transporter.verify();

  return transporter.sendMail({
    from: process.env.EMAIL_USER,
    to,
    subject: "Food Delivery App - Email Test",
    text: "Nodemailer setup successfully!",
  });
}

async function sendPasswordResetOtpEmail(to, otp) {
  await transporter.sendMail({
    from: process.env.EMAIL_USER,
    to,
    subject: "Food Delivery App - Password Reset OTP",
    text: `Your password reset OTP is: ${otp}

This OTP expires in 10 minutes.

If you did not request a password reset, please ignore this email.`,
    html: `
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2>Reset Your Password</h2>
        <p>Use this OTP to reset your Food Delivery App password:</p>
        <div style="font-size: 30px; font-weight: bold;
          letter-spacing: 8px; color: #FF6B35; padding: 16px 0;">
          ${otp}
        </div>
        <p>This OTP expires in 10 minutes.</p>
        <p>If you did not request this, please ignore this email.</p>
      </div>
    `,
  });
}




async function sendEmailVerificationOtpEmail(to, otp) {
  try {
    const info = await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to,
      subject: "Food Delivery App - Email Test",
      text: `Your email verification OTP is: ${otp}

This OTP expires in 10 minutes.

If you did not create this account, please ignore this email.`,
    });

    console.log("OTP recipient:", to);
    console.log("Accepted:", info.accepted);
    console.log("Rejected:", info.rejected);
    console.log("Response:", info.response);
    console.log("Message ID:", info.messageId);

    return info;
  } catch (error) {
    console.error("OTP email failed:", error.message);
    throw error;
  }
}




module.exports = {
  sendTestEmail,
  sendPasswordResetOtpEmail,
  sendEmailVerificationOtpEmail,
  verifyEmailConnection,
};
