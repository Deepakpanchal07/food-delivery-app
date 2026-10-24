const mongoose = require("mongoose");

const menuItemSchema = new mongoose.Schema({
    restaurantId:{
        type: mongoose.Schema.Types.ObjectId,
        ref: "Restaurant ",
        required: true,
        index:true,
    },
    name: {
        type: String,
        required: true,
        trim:true,
    },
    description:{
        type: String,
        default: "",

    },
    price: {
        type:Number,
        required:true,
        min:0,
    },
    imageUrl:{
        type: String,
        default:"Main Course",
    },
    isAvailable:{
        type: Boolean,
        default: true,
    },
    
},
{timeStamps:true}
);

module.exports = mongoose.model("MenuItem",menuItemSchema);