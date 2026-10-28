const express = require("express");
const {
    register,
    login,
    getProfile,
    updateProfile,
    changePassword,
    forgotPassword,
    verifyOtp,
    resetPassword,
    verifyEmailOtp,
    resendEmailOtp,
} = require("../controllers/authController");
const AuthMiddleware = require("../middleware/authMiddleware");
const adminMiddleware = require("../middleware/adminMiddleware");
const { getCustomers } = require("../controllers/userController");
const router = express.Router();



router.post("/register", register);
router.post("/login", login);
router.get("/me", AuthMiddleware,getProfile);
router.put("/profile", AuthMiddleware, updateProfile);  
router.post("/change-password", AuthMiddleware, changePassword); 
router.post("/forgot-password",forgotPassword);
router.post("/verify-otp",verifyOtp)
router.post("/reset-password",resetPassword);
router.get("/customers", AuthMiddleware, adminMiddleware, getCustomers);
router.post("/verify-email-otp", verifyEmailOtp);
router.post("/resend-email-otp", resendEmailOtp);

 
 
module.exports = router;