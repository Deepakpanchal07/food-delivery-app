const express = require("express");
const reviewRoutes = require("./routes/reviewRoutes");
const orderRoutes = require('./routes/orderRoutes');
const emailRoutes = require("./routes/emailRoutes");
require("dotenv").config();
const cors = require("cors");
const authRoutes = require("./routes/authRoutes");
const mongoose = require("mongoose");
const restaurantRoutes = require("./routes/restaurantRoutes");
const menuRoutes = require("./routes/menuRoutes");




const app = express();
console.log("Email user loaded:", Boolean(process.env.EMAIL_USER));
console.log("Email password loaded:", Boolean(process.env.EMAIL_PASS));

app.use(cors());

app.use(express.json());
app.use("/api/reviews", reviewRoutes);
app.use("/api/restaurants",restaurantRoutes);
app.use("/api/auth", authRoutes);
app.use("/api/email", emailRoutes);

app.use("/api/menu", menuRoutes);
app.use("/api/orders",orderRoutes);


app.get("/",(req,res) =>{
    res.status(200).json({
        success: true,
        message: "Food Delivery app is running!",
    });
});
app.get("/api/health",(req,res)=>{
    const connected = mongoose.connection.readyState ===1;
    res.status(connected ? 200:500).json({
        success: true,
        message: connected ? "API and database are working!"
                           : "Database is disconnected",
                           database:connected ? "connected" : "disconnected" 
    });
});

async function startServer(){
    try{
        const mongoUri = process.env.MONGODB_URI;

        if(!mongoUri) {
            throw new Error("MONGODB_URI is missing in .env");
        }
        await mongoose.connect(mongoUri);
        console.log("MongoDB connected Sucessfully!");

        const PORT = process.env.PORT || 5000;

        app.listen(PORT,"0.0.0.0",()=>{
            console.log(`server running on port ${PORT}`);
            console.log(`Health: http://localhost:${PORT}/api/health`);
        });
    }catch(error){
        console.error("Startup failed:",error.message);
        process.exit(1);
    }
}

startServer();