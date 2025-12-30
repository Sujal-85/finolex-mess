const express = require('express');
const router = express.Router();
const Notification = require('../models/Notification');

// Get all notifications (sorted by newest first)
router.get('/', async (req, res) => {
    try {
        const { userId } = req.query;
        let query = {};

        if (userId) {
            query = {
                $or: [
                    { userId: userId },
                    { userId: null },
                    { userId: { $exists: false } }
                ]
            };
        } else {
            // SECURITY FIX: If no userId provided, only return global notifications
            // Do NOT return notifications meant for specific users
            query = {
                $or: [
                    { userId: null },
                    { userId: { $exists: false } }
                ]
            };
        }

        const notifications = await Notification.find(query).sort({ createdAt: -1 });
        res.json(notifications);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Mark as read
router.patch('/:id/read', async (req, res) => {
    try {
        const notification = await Notification.findByIdAndUpdate(
            req.params.id,
            { isRead: true },
            { new: true }
        );
        res.json(notification);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Delete notification
router.delete('/:id', async (req, res) => {
    try {
        await Notification.findByIdAndDelete(req.params.id);
        res.json({ message: 'Notification deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
