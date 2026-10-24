
const User = require("../models/User");
const crypto = require("crypto");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const {
  sendPasswordResetOtpEmail,
  sendEmailVerificationOtpEmail,
} = require("../services/emailService");


function generateToken(userId) {
  const secret = process.env.JWT_SECRET;

  if (!secret) {
    throw new Error("JWT_SECRET is missing in .env");
  }

  return jwt.sign(
    { id: userId },
    secret,
    { expiresIn: "7d" }
  );
}


const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (
      typeof name !== "string" ||
      typeof email !== "string" ||
      typeof password !== "string" ||
      !name.trim() ||
      !email.trim() ||
      !password
    ) {
      return res.status(400).json({
        success: false,
        message: "Name, email and password are required",
      });
    }

    if (name.trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: "Name must contain at least 2 characters",
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 8 characters",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({
      email: normalizedEmail,
    });

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: "This email is already registered",
      });
    }

    const hashedPassword = await bcrypt.hash(password, 12);
    const otp = crypto.randomInt(100000, 1000000).toString();

    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: hashedPassword,
      emailVerified: false,
      emailVerificationOtp: crypto
        .createHash("sha256")
        .update(otp)
        .digest("hex"),
      emailVerificationOtpExpires: new Date(
        Date.now() + 10 * 60 * 1000
      ),
      emailVerificationOtpAttempts: 0,
    });

    try {
      await sendEmailVerificationOtpEmail(user.email, otp);
    } catch (emailError) {
      await User.deleteOne({ _id: user._id });

      console.error(
        "Verification email error:",
        emailError.message
      );

      return res.status(500).json({
        success: false,
        message: "Unable to send verification email. Please try again.",
      });
    }

    return res.status(201).json({
      success: true,
      message:
        "Account created. Please verify your email using the OTP sent to you.",
      data: {
        email: user.email,
        requiresEmailVerification: true,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "This email is already registered",
      });
    }

    console.error("Register error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to create account. Please try again.",
    });
  }
};



const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select("+password");

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }

    const passwordMatches = await bcrypt.compare(
      password,
      user.password
    );

    if (!passwordMatches) {
      return res.status(401).json({
        success: false,
        message: "Invalid email or password",
      });
    }
    
if (user.emailVerified !== true) {
  return res.status(403).json({
    success: false,
    message: "Please verify your email before logging in.",
    requiresEmailVerification: true,
  });
}


    const token = generateToken(user._id.toString());

    return res.status(200).json({
      success: true,
      message: "Login successful",
      data: {
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
        },
      },
    });
  } catch (error) {
    console.error("Login error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to login. Please try again.",
    });
  }
};




const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id)
      .select('name email role createdAt');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          role: user.role || 'customer',
          createdAt: user.createdAt,
        },
      },
    });
  } catch (error) {
    console.error('Get profile error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'Unable to load profile',
    });
  }
};


const updateProfile = async (req,res)=>{
  try{
    const {name,email}=req.body;

    if(!name || !email){
      return res.status(400).json({
        success: false,
        message: "Name ans Email are required",
      });
    }
    if(name.trim().length<2){
      return res.status(400).json({
        suceess: false,
        message: "Name must conatin at least 2 characters",
      });
    }
    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({
      email: normalizedEmail,
      _id: {$ne: req.user.id},
    });
    if(existingUser) {
      return res.status(409).json({
        success: false,
        message: "This email is already registered",
      });
    }
    const user = await User.findByIdAndUpdate(
      req.user.id,
      {
        name: name.trim(),
        email:normalizedEmail,
      },
      {
        new: true,
        runValidators: true,
      }
    ).select("name email createdAt");

    if(!user){
      return res.status(404).json({
        success:false,
        message:"User not found",
      });
    }
    return res.status(200).json({
      success: true,
      message: "Profile Updagted successfully",
      data:{
        user:{
          id: user._id.toString(),
          name: user.name,
          email: user.email,
          createdAt: user.createdAt,
        }
      }
    });
  }catch(error){
    if(error.code == 11000){
      return res.status(409).json({
        success: false,
        message: "This email is aleady registered",
      });
    }
    console.error("Updated profile error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to update profile"
    })
  }
}

const changePassword = async (req,res)=>{
    try{
      const {currentPassword,newPassword} = req.body;

      if(!currentPassword || !newPassword){
        return res.status(400).json({
          success: false,
          message: "Current and New password are required",
        });
      }
      if(newPassword.length<8) {
        return res.status(400).json({
          success: false,
          message:"new password must be at least 8 characters"
        });
      }
      const user= await User.findById(req.user.id).select("+password");

      if(!user) {
        return res.status(404).json({
          success: false,
          message: "User not Found"
        });
      }
      const passwordMatches = await bcrypt.compare(currentPassword,user.password);

      if(!passwordMatches){
        return res.status(400).json({
          success: false,
          message:"current password is incorrect"
        });
      }
      const samePassword = await bcrypt.compare(
        newPassword,
        user.password,
      );

      if(samePassword){
        return res.status(400).json({
          success: false,
          message: "New password must be different",
        });
      }
      user.password = await bcrypt.hash(newPassword,12);
      await user.save();

      return res.status(200).json({
        success: true,
        message:"Password change Successfully.Please login again",
      });
    }catch(error){
      console.error("change password error:", error.message);

      return res.status(500).json({
        success: false,
        message: "Unable to change password",
      });
    }
}



const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email || !email.trim()) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });

    // Same response whether the account exists or not.
    const message =
      "If an account exists with this email, an OTP will be sent.";

    if (!user) {
      return res.status(200).json({ success: true, message });
    }

    // Generate a six-digit OTP.
    const otp = crypto.randomInt(100000, 1000000).toString();

    // Store only the hashed OTP.
    user.passwordResetOtp = crypto
      .createHash("sha256")
      .update(otp)
      .digest("hex");

    user.passwordResetOtpExpires = new Date(Date.now() + 10 * 60 * 1000);
    user.passwordResetOtpAttempts = 0;

    // Invalidate any previous reset grant.
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;

    await user.save();

    try {
      await sendPasswordResetOtpEmail(user.email, otp);
    } catch (error) {
      console.error("OTP email error:", error.message);

      user.passwordResetOtp = undefined;
      user.passwordResetOtpExpires = undefined;
      user.passwordResetOtpAttempts = 0;
      await user.save();

      return res.status(500).json({
        success: false,
        message: "Unable to send OTP. Please try again later.",
      });
    }

    return res.status(200).json({
      success: true,
      message,
    });
  } catch (error) {
    console.error("Forgot password error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Something went wrong. Please try again.",
    });
  }
};


const verifyOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: "Email and OTP are required.",
      });
    }

    if (!/^\d{6}$/.test(String(otp))) {
      return res.status(400).json({
        success: false,
        message: "Enter a valid six-digit OTP.",
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select(
      "+passwordResetOtp +passwordResetOtpExpires " +
      "+passwordResetOtpAttempts"
    );

    if (!user || !user.passwordResetOtp || !user.passwordResetOtpExpires) {
      return res.status(400).json({
        success: false,
        message: "OTP is invalid or expired. Request a new OTP.",
      });
    }

    if (user.passwordResetOtpExpires <= new Date()) {
      user.passwordResetOtp = undefined;
      user.passwordResetOtpExpires = undefined;
      user.passwordResetOtpAttempts = 0;
      await user.save();

      return res.status(400).json({
        success: false,
        message: "OTP has expired. Request a new OTP.",
      });
    }

    if ((user.passwordResetOtpAttempts || 0) >= 5) {
      user.passwordResetOtp = undefined;
      user.passwordResetOtpExpires = undefined;
      user.passwordResetOtpAttempts = 0;
      await user.save();

      return res.status(429).json({
        success: false,
        message: "Too many incorrect attempts. Request a new OTP.",
      });
    }

    const hashedOtp = crypto
      .createHash("sha256")
      .update(String(otp))
      .digest("hex");

    if (hashedOtp !== user.passwordResetOtp) {
      user.passwordResetOtpAttempts =
        (user.passwordResetOtpAttempts || 0) + 1;

      await user.save();

      return res.status(400).json({
        success: false,
        message: "Incorrect OTP. Please try again.",
      });
    }

    // OTP verified: issue a short-lived password-reset grant.
    const resetToken = crypto.randomBytes(32).toString("hex");

    user.passwordResetToken = crypto
      .createHash("sha256")
      .update(resetToken)
      .digest("hex");

    user.passwordResetExpires = new Date(Date.now() + 10 * 60 * 1000);

    // OTP can no longer be reused.
    user.passwordResetOtp = undefined;
    user.passwordResetOtpExpires = undefined;
    user.passwordResetOtpAttempts = 0;

    await user.save();

    return res.status(200).json({
      success: true,
      message: "OTP verified successfully.",
      resetToken,
    });
  } catch (error) {
    console.error("OTP verification error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to verify OTP. Please try again.",
    });
  }
};


const resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Reset token and new password are required.",
      });
    }

    if (typeof newPassword !== "string" || newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: "Password must be at least 8 characters long.",
      });
    }

    const hashedToken = crypto
      .createHash("sha256")
      .update(token)
      .digest("hex");

    const user = await User.findOne({
      passwordResetToken: hashedToken,
      passwordResetExpires: { $gt: new Date() },
    }).select("+password +passwordResetToken +passwordResetExpires");

    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Reset session is invalid or expired. Verify OTP again.",
      });
    }

    user.password = await bcrypt.hash(newPassword, 12);
    user.passwordResetToken = undefined;
    user.passwordResetExpires = undefined;

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Password reset successfully. Please log in again.",
    });
  } catch (error) {
    console.error("Reset password error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to reset password. Please try again.",
    });
  }
};


const verifyEmailOtp = async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (
      typeof email !== "string" ||
      !email.trim() ||
      !/^\d{6}$/.test(String(otp || ""))
    ) {
      return res.status(400).json({
        success: false,
        message: "Enter a valid email and six-digit OTP.",
      });
    }

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select(
      "+emailVerificationOtp " +
      "+emailVerificationOtpExpires " +
      "+emailVerificationOtpAttempts"
    );

    if (!user) {
      return res.status(400).json({
        success: false,
        message: "Invalid email or OTP.",
      });
    }

    if (user.emailVerified === true) {
      return res.status(200).json({
        success: true,
        message: "Email already verified. Please log in.",
      });
    }

    if (
      !user.emailVerificationOtp ||
      !user.emailVerificationOtpExpires ||
      user.emailVerificationOtpExpires <= new Date()
    ) {
      return res.status(400).json({
        success: false,
        message: "OTP is invalid or expired. Request a new OTP.",
      });
    }

    if ((user.emailVerificationOtpAttempts || 0) >= 5) {
      user.emailVerificationOtp = undefined;
      user.emailVerificationOtpExpires = undefined;
      user.emailVerificationOtpAttempts = 0;
      await user.save();

      return res.status(429).json({
        success: false,
        message: "Too many attempts. Request a new OTP.",
      });
    }

    const hashedOtp = crypto
      .createHash("sha256")
      .update(String(otp))
      .digest("hex");

    if (hashedOtp !== user.emailVerificationOtp) {
      user.emailVerificationOtpAttempts =
        (user.emailVerificationOtpAttempts || 0) + 1;

      await user.save();

      return res.status(400).json({
        success: false,
        message: "Incorrect OTP. Please try again.",
      });
    }

    user.emailVerified = true;
    user.emailVerificationOtp = undefined;
    user.emailVerificationOtpExpires = undefined;
    user.emailVerificationOtpAttempts = 0;

    await user.save();

    return res.status(200).json({
      success: true,
      message: "Email verified successfully. You can now log in.",
    });
  } catch (error) {
    console.error("Email verification error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to verify email. Please try again.",
    });
  }
};


module.exports = { register, login, getProfile, updateProfile,changePassword,resetPassword,verifyOtp,forgotPassword,verifyEmailOtp};
