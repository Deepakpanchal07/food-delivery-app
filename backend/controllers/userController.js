
const User = require("../models/User");

const getCustomers = async (req, res) => {
  try {
    const search = (req.query.search || "").trim();

    // Escape special regex characters from search input.
    const escapedSearch = search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    const filter = {
      role: "customer",
    };

    if (escapedSearch) {
      filter.$or = [
        { name: { $regex: escapedSearch, $options: "i" } },
        { email: { $regex: escapedSearch, $options: "i" } },
      ];
    }

    const customers = await User.find(filter)
      .select("_id name email createdAt")
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({
      success: true,
      count: customers.length,
      data: customers,
    });
  } catch (error) {
    console.error("Get customers error:", error.message);

    return res.status(500).json({
      success: false,
      message: "Unable to fetch customers.",
    });
  }
};

module.exports = { getCustomers };
