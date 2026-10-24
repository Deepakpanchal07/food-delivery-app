const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Name is required"],
      trim: true,
      minlength: 2,
      maxlength: 50,
    },

    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      trim: true,
    },

    password: {
      type: String,
      required: [true, "Password is required"],
      minlength: 8,
      select: false,
    },

    // OTP verification fields
    passwordResetOtp: {
      type: String,
      select: false,
    },

    passwordResetOtpExpires: {
      type: Date,
      select: false,
    },

    passwordResetOtpAttempts: {
      type: Number,
      default: 0,
      select: false,
    },

    // Temporary reset grant created after OTP verification
    passwordResetToken: {
      type: String,
      select: false,
    },

    passwordResetExpires: {
      type: Date,
      select: false,
    },
    role:{
      type: String,
      enum :['customer','admin'],
      default: 'customer',
    },
    emailVerified: {
  type: Boolean,
  default: false,
},

emailVerificationOtp: {
  type: String,
  select: false,
},

emailVerificationOtpExpires: {
  type: Date,
  select: false,
},

emailVerificationOtpAttempts: {
  type: Number,
  default: 0,
  select: false,
},
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("User", userSchema);