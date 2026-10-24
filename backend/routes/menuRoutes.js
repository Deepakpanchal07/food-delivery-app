
const express = require("express");
const mongoose = require("mongoose");
const Restaurant = require("../models/Restaurant");
const MenuItem = require("../models/MenuItem");

const router = express.Router();

// GET: Fetch menu items for a restaurant
router.get("/restaurant/:restaurantId", async (req, res) => {
  try {
    const { restaurantId } = req.params;

    if (!mongoose.isValidObjectId(restaurantId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid restaurant ID",
      });
    }

    const restaurant = await Restaurant.findById(restaurantId);

    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: "Restaurant not found",
      });
    }

    const menuItems = await MenuItem.find({
      restaurantId,
    }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      menuItems,
    });
  } catch (error) {
    console.error("Get menu error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to fetch menu",
      error: error.message,
    });
  }
});

// POST: Add a food item
router.post("/", async (req, res) => {
  try {
    const {
      restaurantId,
      name,
      description,
      price,
      imageUrl,
      category,
      isAvailable,
    } = req.body || {};

    if (
      !restaurantId ||
      !mongoose.isValidObjectId(restaurantId)
    ) {
      return res.status(400).json({
        success: false,
        message: "Valid restaurant ID is required",
      });
    }

    if (typeof name !== "string" || !name.trim()) {
      return res.status(400).json({
        success: false,
        message: "Food name is required",
      });
    }

    if (
      price === undefined ||
      price === null ||
      price === "" ||
      !Number.isFinite(Number(price)) ||
      Number(price) < 0
    ) {
      return res.status(400).json({
        success: false,
        message: "A valid price is required",
      });
    }

    const restaurant = await Restaurant.findById(restaurantId);

    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: "Restaurant not found",
      });
    }

    const menuItem = await MenuItem.create({
      restaurantId,
      name: name.trim(),
      description: description || "",
      price: Number(price),
      imageUrl: imageUrl || "",
      category: category || "Main Course",
      isAvailable: isAvailable ?? true,
    });

    return res.status(201).json({
      success: true,
      message: "Food item added successfully",
      menuItem,
    });
  } catch (error) {
    console.error("Add menu item error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to add food item",
      error: error.message,
    });
  }
});

// PUT: Update a food item
router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const {
      name,
      description,
      price,
      imageUrl,
      category,
      isAvailable,
    } = req.body || {};

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid food item ID",
      });
    }

    const updates = {};

    if (name !== undefined) {
      if (typeof name !== "string" || !name.trim()) {
        return res.status(400).json({
          success: false,
          message: "Food name is required",
        });
      }
      updates.name = name.trim();
    }

    if (description !== undefined) {
      updates.description = description;
    }

    if (price !== undefined) {
      if (
        price === "" ||
        !Number.isFinite(Number(price)) ||
        Number(price) < 0
      ) {
        return res.status(400).json({
          success: false,
          message: "A valid price is required",
        });
      }
      updates.price = Number(price);
    }

    if (imageUrl !== undefined) {
      updates.imageUrl = imageUrl;
    }

    if (category !== undefined) {
      updates.category = category;
    }

    if (isAvailable !== undefined) {
      if (typeof isAvailable !== "boolean") {
        return res.status(400).json({
          success: false,
          message: "isAvailable must be true or false",
        });
      }
      updates.isAvailable = isAvailable;
    }

    const menuItem = await MenuItem.findByIdAndUpdate(
      id,
      { $set: updates },
      { new: true, runValidators: true }
    );

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: "Food item not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Food item updated successfully",
      menuItem,
    });
  } catch (error) {
    console.error("Update menu item error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to update food item",
      error: error.message,
    });
  }
});

// PATCH: Change food availability
router.patch("/:id/availability", async (req, res) => {
  try {
    const { id } = req.params;
    const { isAvailable } = req.body || {};

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid food item ID",
      });
    }

    if (typeof isAvailable !== "boolean") {
      return res.status(400).json({
        success: false,
        message: "isAvailable must be true or false",
      });
    }

    const menuItem = await MenuItem.findByIdAndUpdate(
      id,
      { $set: { isAvailable } },
      { new: true, runValidators: true }
    );

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: "Food item not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Food availability updated successfully",
      menuItem,
    });
  } catch (error) {
    console.error("Availability update error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to update availability",
      error: error.message,
    });
  }
});

// DELETE: Remove a food item
router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.isValidObjectId(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid food item ID",
      });
    }

    const menuItem = await MenuItem.findByIdAndDelete(id);

    if (!menuItem) {
      return res.status(404).json({
        success: false,
        message: "Food item not found",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Food item deleted successfully",
    });
  } catch (error) {
    console.error("Delete menu item error:", error);

    return res.status(500).json({
      success: false,
      message: "Failed to delete food item",
      error: error.message,
    });
  }
});

module.exports = router;
