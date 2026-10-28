const { sendTestEmail } = require("./services/emailService");

async function main() {
  try {
    const result = await sendTestEmail("r32323459@gmail.com");
    console.log("Accepted:", result.accepted);
    console.log("Message ID:", result.messageId);
  } catch (error) {
    console.error("Email failed:", error.message);
  }
}

main();