
const express = require('express');
const mongoose = require('mongoose');
const User = require('../models/User');

const Order = require('../models/Order');
const Restaurant = require('../models/Restaurant');
const MenuItem = require('../models/MenuItem');
const AuthMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// GET: Logged-in customer's orders
router.get('/my-orders', AuthMiddleware, async (req, res) => {
  try {
    const customerId = req.user.id;

    if (!mongoose.isValidObjectId(customerId)) {
      return res.status(401).json({
        success: false,
        message: 'Invalid customer session.',
      });
    }

    const orders = await Order.find({ customerId })
      .populate('restaurantId', 'name imageUrl')
      .sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      orders,
    });
  } catch (error) {
    console.error('Fetch my orders error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to fetch your orders.',
    });
  }
});

// POST: Place an order for the logged-in customer
router.post('/', AuthMiddleware, async (req, res) => {
  try {
    const {
      customerName,
      phone,
      address,
      city,
      pincode,
      restaurantId,
      items,
    } = req.body || {};

    const customerId = req.user.id;

    if (
      !mongoose.isValidObjectId(customerId) ||
      typeof customerName !== 'string' ||
      !customerName.trim() ||
      typeof phone !== 'string' ||
      !/^[6-9]\d{9}$/.test(phone) ||
      typeof address !== 'string' ||
      !address.trim() ||
      typeof city !== 'string' ||
      !city.trim() ||
      typeof pincode !== 'string' ||
      !/^\d{6}$/.test(pincode) ||
      !mongoose.isValidObjectId(restaurantId) ||
      !Array.isArray(items) ||
      items.length === 0
    ) {
      return res.status(400).json({
        success: false,
        message: 'Please provide valid delivery and order details.',
      });
    }

    const restaurant = await Restaurant.findById(restaurantId);

    if (!restaurant) {
      return res.status(404).json({
        success: false,
        message: 'Restaurant not found.',
      });
    }

    if (restaurant.isOpen === false) {
      return res.status(400).json({
        success: false,
        message: 'Restaurant is currently closed.',
      });
    }

    const verifiedItems = [];
    let subtotal = 0;

    for (const requestedItem of items) {
      const { menuItemId, quantity } = requestedItem || {};

      if (
        !mongoose.isValidObjectId(menuItemId) ||
        !Number.isInteger(quantity) ||
        quantity < 1 ||
        quantity > 50
      ) {
        return res.status(400).json({
          success: false,
          message: 'Invalid menu item or quantity.',
        });
      }

      const menuItem = await MenuItem.findById(menuItemId);

      if (!menuItem) {
        return res.status(400).json({
          success: false,
          message: 'A selected food item was not found.',
        });
      }

      if (String(menuItem.restaurantId) !== String(restaurantId)) {
        return res.status(400).json({
          success: false,
          message: 'Food items must belong to the selected restaurant.',
        });
      }

      if (menuItem.isAvailable === false) {
        return res.status(400).json({
          success: false,
          message: `${menuItem.name} is unavailable.`,
        });
      }

      const price = Number(menuItem.price);

      if (!Number.isFinite(price) || price < 0) {
        return res.status(400).json({
          success: false,
          message: 'Invalid food item price.',
        });
      }

      subtotal += price * quantity;

      verifiedItems.push({
        menuItemId: menuItem._id,
        name: menuItem.name,
        price,
        quantity,
      });
    }

    const deliveryFee = Number(restaurant.deliveryFee ?? 0);
    console.log("Restaurant name:", restaurant.name);
    console.log("Food subtotal:", subtotal);
    console.log("Delivery fee from DB:", restaurant.deliveryFee);
    console.log("Final total:", subtotal + deliveryFee);

    if (!Number.isFinite(deliveryFee) || deliveryFee < 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid delivery fee.',
      });
    }

    const order = await Order.create({
      customerId,
      customerName: customerName.trim(),
      phone,
      address: address.trim(),
      city: city.trim(),
      pincode,
      restaurantId: restaurant._id,
      items: verifiedItems,
      subtotal,
      deliveryFee,
      totalAmount: subtotal + deliveryFee,
    });

    return res.status(201).json({
      success: true,
      message: 'Order placed successfully!',
      order,
    });
  } catch (error) {
    console.error('Place order error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to place order.',
    });
  }
});
// GET: Track one order belonging to the logged-in customer
router.get('/track/:orderId', AuthMiddleware, async (req, res) => {
  try {
    const { orderId } = req.params;
    const customerId = req.user.id;

    if (!mongoose.isValidObjectId(orderId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order ID.',
      });
    }

    const order = await Order.findOne({
      _id: orderId,
      customerId,
    }).populate('restaurantId', 'name imageUrl');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found.',
      });
    }

    return res.status(200).json({
      success: true,
      order: {
        id: order._id,
        status: order.status,
        restaurant: order.restaurantId,
        items: order.items,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        totalAmount: order.totalAmount,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
      },
    });
  } catch (error) {
    console.error('Track order error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to track order.',
    });
  }
});



const allowedTransitions = {
  'Placed': ['Confirmed', 'Cancelled'],
  'Confirmed': ['Preparing', 'Cancelled'],
  'Preparing': ['Out for Delivery', 'Cancelled'],
  'Out for Delivery': ['Delivered'],
  'Delivered': [],
  'Cancelled': [],
};


 // PATCH: Cancel an order by its logged-in customer
router.patch('/:orderId/cancel', AuthMiddleware, async (req, res) => {
  try {
    const { orderId } = req.params;
    const customerId = req.user.id;

    // Validate order ID
    if (!mongoose.isValidObjectId(orderId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order ID.',
      });
    }

    // Find only this customer's order
    const order = await Order.findOne({
      _id: orderId,
      customerId,
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found.',
      });
    }

    // Cancellation is allowed only while Placed
    if (order.status !== 'Placed') {
      return res.status(400).json({
        success: false,
        message: `Order cannot be cancelled because its status is ${order.status}.`,
      });
    }

    order.status = 'Cancelled';
    await order.save();

    return res.status(200).json({
      success: true,
      message: 'Order cancelled successfully.',
      order: {
        id: order._id,
        status: order.status,
        updatedAt: order.updatedAt,
      },
    });
  } catch (error) {
    console.error('Cancel order error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to cancel order.',
    });
  }
});


/* GET: Fetch all orders for Admin Dashboard */
router.get('/admin/all', AuthMiddleware, async (req, res) => {
  try {
    // Admin-only access
    if (req.user?.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admin access required.',
      });
    }

    const orders = await Order.find()
      .populate('restaurantId', 'name imageUrl')
      .sort({ createdAt: -1 })
      .lean();

    const formattedOrders = orders.map((order) => ({
      ...order,
      restaurantName:
        order.restaurantId?.name || 'Restaurant order',
    }));

    return res.status(200).json({
      success: true,
      count: formattedOrders.length,
      orders: formattedOrders,
    });
  } catch (error) {
    console.error('Admin fetch all orders error:', error);
    
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch all orders.',
    });
  }
});



// PATCH: Update order status (admin only)
router.patch('/:orderId/status', AuthMiddleware, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Only an admin can update order status.',
      });
    }

    const { orderId } = req.params;
    const { status } = req.body || {};

    if (!mongoose.isValidObjectId(orderId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order ID.',
      });
    }

    if (
      typeof status !== 'string' ||
      !Object.prototype.hasOwnProperty.call(allowedTransitions, status)
    ) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order status.',
      });
    }

    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found.',
      });
    }

    const nextStatuses = allowedTransitions[order.status] || [];

    if (!nextStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot change status from ${order.status} to ${status}.`,
      });
    }

    order.status = status;
    await order.save();

    return res.status(200).json({
      success: true,
      message: 'Order status updated successfully.',
      order: {
        id: order._id,
        status: order.status,
        updatedAt: order.updatedAt,
      },
    });
  } catch (error) {
    console.error('Update order status error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to update order status.',
    });
  }
});


 // DELETE: Delete a cancelled order belonging to the logged-in customer
router.delete('/:orderId', AuthMiddleware, async (req, res) => {
  try {
    const { orderId } = req.params;
    const customerId = req.user.id;

    if (!mongoose.isValidObjectId(orderId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid order ID.',
      });
    }

    const order = await Order.findOne({
      _id: orderId,
      customerId,
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found.',
      });
    }

    if (order.status !== 'Cancelled') {
      return res.status(400).json({
        success: false,
        message: 'Only cancelled orders can be deleted.',
      });
    }

    await Order.deleteOne({ _id: order._id });

    return res.status(200).json({
      success: true,
      message: 'Cancelled order deleted successfully.',
    });
  } catch (error) {
    console.error('Delete order error:', error);

    return res.status(500).json({
      success: false,
      message: 'Unable to delete order.',
    });
  }
});


// ADMIN ANALYTICS
router.get('/admin/analytics', AuthMiddleware, async (req, res) => {
  try {
    if (req.user?.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admin access required',
      });
    }

    const [
      totalOrders,
      totalCustomers,
      totalRestaurants,
      deliveredOrders,
      statusBreakdown,
      recentOrders,
    ] = await Promise.all([
      Order.countDocuments(),
      User.countDocuments({ role: { $ne: 'admin' } }),
      Restaurant.countDocuments(),

      Order.aggregate([
        { $match: { status: 'Delivered' } },
        {
          $group: {
            _id: null,
            revenue: { $sum: '$totalAmount' },
            count: { $sum: 1 },
          },
        },
      ]),

      Order.aggregate([
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 },
          },
        },
      ]),

      Order.find()
        .sort({ createdAt: -1 })
        .limit(5)
        .select('customerName totalAmount status createdAt restaurantId')
        .populate('restaurantId', 'name')
        .lean(),
    ]);

    const statusCounts = {};
    statusBreakdown.forEach((item) => {
      statusCounts[item._id] = item.count;
    });

    res.json({
      success: true,
      analytics: {
        totalOrders,
        totalCustomers,
        totalRestaurants,
        deliveredOrders: deliveredOrders[0]?.count || 0,
        totalRevenue: deliveredOrders[0]?.revenue || 0,
        statusBreakdown: statusCounts,
        recentOrders: recentOrders.map((order) => ({
          id: order._id,
          customerName: order.customerName,
          restaurantName: order.restaurantId?.name || 'Unknown',
          totalAmount: order.totalAmount,
          status: order.status,
          createdAt: order.createdAt,
        })),
      },
    });
  } catch (error) {
    console.error('Admin analytics error:', error);

    res.status(500).json({
      success: false,
      message: 'Failed to load analytics',
    });
  }
});



module.exports = router;
