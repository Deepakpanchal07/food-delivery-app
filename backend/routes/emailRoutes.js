
const express = require("express");
const router = express.Router();

const { sendTestEmail } = require("../services/emailService");

router.post("/test-email", async (req, res) => {
  try {
    const { to } = req.body;

    if (!to) {
      return res.status(400).json({
        success: false,
        message: "Recipient email is required",
      });
    }

    await sendTestEmail(to);

    return res.status(200).json({
      success: true,
      message: "Test email sent successfully",
    });
  } catch (error) {
    console.error("Email error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to send email",
    });
  }
});

module.exports = router;
