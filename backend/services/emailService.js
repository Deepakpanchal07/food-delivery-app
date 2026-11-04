require("dotenv").config();

const BREVO_BASE = "https://api.brevo.com/v3";

function brevoHeaders() {
  if (!process.env.BREVO_API_KEY) {
    throw new Error("BREVO_API_KEY is missing");
  }
  return {
    "api-key": process.env.BREVO_API_KEY,
    "Content-Type": "application/json",
    accept: "application/json",
  };
}

async function brevoFetch(path, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 10000);

  try {
    const res = await fetch(`${BREVO_BASE}${path}`, {
      ...options,
      headers: brevoHeaders(),
      signal: controller.signal,
    });

    if (!res.ok) {
      throw new Error(`Brevo ${res.status}: ${await res.text()}`);
    }

    return res.json();
  } finally {
    clearTimeout(timer);
  }
}

async function sendEmail({ to, subject, text, html }) {
  return brevoFetch("/smtp/email", {
    method: "POST",
    body: JSON.stringify({
      sender: { email: process.env.EMAIL_USER, name: "Food Delivery App" },
      to: [{ email: to }],
      subject,
      textContent: text,
      htmlContent: html,
    }),
  });
}

async function verifyEmailConnection() {
  try {
    await brevoFetch("/account");
    console.log("✅ Brevo email connection successful");
    return true;
  } catch (error) {
    console.error("❌ Brevo email connection failed:", error.message);
    return false;
  }
}

async function sendTestEmail(to) {
  return sendEmail({
    to,
    subject: "Food Delivery App - Email Test",
    text: "Email setup successful!",
  });
}

async function sendPasswordResetOtpEmail(to, otp) {
  await sendEmail({
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
    const info = await sendEmail({
      to,
      subject: "Food Delivery App - Verify Your Email",
      text: `Your email verification OTP is: ${otp}

This OTP expires in 10 minutes.

If you did not create this account, please ignore this email.`,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px;">
          <h2>Verify Your Email</h2>
          <p>Use this OTP to verify your Food Delivery App account:</p>
          <div style="font-size: 30px; font-weight: bold;
            letter-spacing: 8px; color: #FF6B35; padding: 16px 0;">
            ${otp}
          </div>
          <p>This OTP expires in 10 minutes.</p>
          <p>If you did not create this account, please ignore this email.</p>
        </div>
      `,
    });

    console.log("OTP email sent to:", to, "| Message ID:", info.messageId);
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