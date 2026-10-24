
const express = require("express");
const mongoose = require("mongoose");
const Restaurant = require("../models/Restaurant");

const router = express.Router();

// GET: Fetch all restaurants
router.get("/", async (req, res) => {
  try {
    const restaurants = await Restaurant.find().sort({
      createdAt: -1,
    });

    res.status(200).json({
      success: true,
      count: restaurants.length,
      data: restaurants,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch restaurants",
    });
  }
});

// GET: Fetch one restaurant by ID
router.get("/:id", async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid restaurant ID",
      });
    }

    const restaurant = await Restaurant.findById(req.params.id);

    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: "Restaurant not found",
      });
    }

    res.status(200).json({
      success: true,
      data: restaurant,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to fetch restaurant",
    });
  }
});

// POST: Create a restaurant
router.post("/", async (req, res) => {
  try {
    const { name, cuisine, description, imageUrl,
      rating, deliveryTime, deliveryFee, isOpen } = req.body;

    if (
      typeof name !== "string" ||
      !name.trim() ||
      typeof cuisine !== "string" ||
      !cuisine.trim()
    ) {
      return res.status(400).json({
        success: false,
        message: "Name and cuisine are required",
      });
    }

    const restaurant = await Restaurant.create({
      name,
      cuisine,
      description,
      imageUrl,
      rating,
      deliveryTime,
      deliveryFee,
      isOpen,
    });

    res.status(201).json({
      success: true,
      message: "Restaurant created successfully",
      data: restaurant,
    });
  } catch (error) {
    if (error.name === "ValidationError") {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    res.status(500).json({
      success: false,
      message: "Failed to create restaurant",
    });
  }
});

// DELETE: Delete a restaurant by ID
router.delete("/:id", async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid restaurant ID",
      });
    }

    const restaurant = await Restaurant.findByIdAndDelete(
      req.params.id
    );

    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: "Restaurant not found",
      });
    }

    res.status(200).json({
      success: true,
      message: "Restaurant deleted successfully",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: "Failed to delete restaurant",
    });
  }
});

 // PUT: Update a restaurant by ID
router.put("/:id", async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid restaurant ID",
      });
    }

    const {
      name,
      cuisine,
      description,
      imageUrl,
      rating,
      deliveryTime,
      deliveryFee,
      isOpen,
    } = req.body || {};

    if (
      typeof name !== "string" ||
      !name.trim() ||
      typeof cuisine !== "string" ||
      !cuisine.trim()
    ) {
      return res.status(400).json({
        success: false,
        message: "Name and cuisine are required",
      });
    }

    const restaurant = await Restaurant.findByIdAndUpdate(
      req.params.id,
      {
        name: name.trim(),
        cuisine: cuisine.trim(),
        description,
        imageUrl,
        rating,
        deliveryTime,
        deliveryFee,
        isOpen,
      },
      {
        new: true,
        runValidators: true,
      }
    );

    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: "Restaurant not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Restaurant updated successfully",
      data: restaurant,
    });
  } catch (error) {
    console.error("Update restaurant error:", error);

    if (error.name === "ValidationError" || error.name === "CastError") {
      return res.status(400).json({
        success: false,
        message: error.message,
      });
    }

    return res.status(500).json({
      success: false,
      message: "Failed to update restaurant",
    });
  }
});


module.exports = router;