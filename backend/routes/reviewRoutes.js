
const express = require("express");
const mongoose = require("mongoose");


const Review = require("../models/Review");
const Restaurant = require("../models/Restaurant");
const User = require("../models/User");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

// Restaurant ki average rating update karna
async function updateRestaurantRating(restaurantId) {
  const result = await Review.aggregate([
    {
      $match: {
        restaurantId: new mongoose.Types.ObjectId(restaurantId),
      },
    },
    {
      $group: {
        _id: "$restaurantId",
        averageRating: { $avg: "$rating" },
      },
    },
  ]);

  const averageRating =
    result.length > 0
      ? Math.round(result[0].averageRating * 10) / 10
      : 0;

  await Restaurant.findByIdAndUpdate(restaurantId, {
    rating: averageRating,
  });

  return averageRating;
}

// GET /api/reviews/restaurant/:restaurantId
// Restaurant ke reviews fetch karna
router.get("/restaurant/:restaurantId", async (req, res) => {
  try {
    const { restaurantId } = req.params;

    if (!mongoose.isValidObjectId(restaurantId)) {
      return res.status(400).json({
        success: false,
        message: "Invalid restaurant ID.",
      });
    }

            const reviews = await Review.find({ restaurantId })
        .populate({
            path: "userId",
            select: "name fullName username firstName lastName",
        })
        .sort({ createdAt: -1 })
        .lean();

    const averageRating =
      reviews.length > 0
        ? Math.round(
            (reviews.reduce((sum, review) => sum + review.rating, 0) /
              reviews.length) *
              10
          ) / 10
        : 0;

    return res.status(200).json({
      success: true,
      count: reviews.length,
      averageRating,
      reviews,
    });
  } catch (error) {
    console.error("Fetch reviews error:", error);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch reviews.",
    });
  }
});

// POST /api/reviews
// Logged-in user review create/update karega
router.post("/", authMiddleware, async (req, res) => {
  try {
    const { restaurantId, rating, comment = "" } = req.body;

    if (!mongoose.isValidObjectId(restaurantId)) {
      return res.status(400).json({
        success: false,
        message: "Valid restaurant ID is required.",
      });
    }

    if (
      typeof rating !== "number" ||
      !Number.isFinite(rating) ||
      rating < 1 ||
      rating > 5
    ) {
      return res.status(400).json({
        success: false,
        message: "Rating must be a number from 1 to 5.",
      });
    }

    if (typeof comment !== "string" || comment.trim().length > 1000) {
      return res.status(400).json({
        success: false,
        message: "Comment must be text with at most 1000 characters.",
      });
    }

    const restaurant = await Restaurant.findById(restaurantId);

    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: "Restaurant not found.",
      });
    }

    const review = await Review.findOneAndUpdate(
      {
        restaurantId,
        userId: req.user.id,
      },
      {
        $set: {
          rating,
          comment: comment.trim(),
        },
      },
      {
        new: true,
        upsert: true,
        runValidators: true,
        setDefaultsOnInsert: true,
      }
    );

    const averageRating = await updateRestaurantRating(restaurantId);

    return res.status(200).json({
      success: true,
      message: "Review saved successfully.",
      averageRating,
      review,
    });
  } catch (error) {
    console.error("Save review error:", error);

    // Handles a possible duplicate-key race condition.
    if (error.code === 11000) {
      return res.status(409).json({
        success: false,
        message: "Review conflict. Please try again.",
      });
    }

    return res.status(500).json({
      success: false,
      message: "Unable to save review.",
    });
  }
});

module.exports = router;
