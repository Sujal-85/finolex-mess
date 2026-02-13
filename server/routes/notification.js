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
                    { recipient: userId }, // CHANGED: userId -> recipient
                    { recipient: null },   // CHANGED: userId -> recipient
                    { recipient: { $exists: false } } // CHANGED: userId -> recipient
                ]
            };
        } else {
            // SECURITY FIX: If no userId provided, only return global notifications
            // Do NOT return notifications meant for specific users
            query = {
                $or: [
                    { recipient: null }, // CHANGED: userId -> recipient
                    { recipient: { $exists: false } } // CHANGED: userId -> recipient
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

// Create Notification (and send FCM)
router.post('/', async (req, res) => {
    try {
        const { recipient, title, message, type } = req.body; // recipient is userId or null for global

        // SILENCE: Profile Updated notifications (as requested by user)
        if (title && title.toLowerCase().includes('profile updated')) {
            console.log('Silencing profile updated notification');
            return res.json({ message: 'Notification silenced' });
        }

        // 1. Save Notification to DB
        const notification = new Notification({
            recipient,
            title,
            message,
            type: type || 'info', // mess, alert, payment, info
            isRead: false
        });
        await notification.save();

        // 2. Send FCM
        const admin = require('../services/firebase');
        const Student = require('../models/Student');

        let tokens = [];

        if (recipient) {
            // Single User
            const student = await Student.findById(recipient);
            if (student && student.fcmToken) {
                tokens.push(student.fcmToken);
            }
        } else {
            // Global Broadcast (All users with tokens)
            // Optional: Filter by settings if needed, but for generic notifications, we might send to all?
            // Let's check settings.pushNotifications
            const students = await Student.find({
                fcmToken: { $exists: true, $ne: null },
                'settings.pushNotifications': { $ne: false }
            }).select('fcmToken');
            tokens = students.map(s => s.fcmToken);
        }

        if (tokens.length > 0) {
            // Send Multicast
            // Batching is good practice
            const batchSize = 500;
            for (let i = 0; i < tokens.length; i += batchSize) {
                const batchTokens = tokens.slice(i, i + batchSize);
                if (batchTokens.length > 0) {
                    await admin.messaging().sendEachForMulticast({
                        notification: { title, body: message },
                        android: {
                            priority: 'high',
                            notification: {
                                channelId: 'high_importance_channel'
                            }
                        },
                        tokens: batchTokens
                    });
                }
            }
            console.log(`FCM sent to ${tokens.length} devices.`);
        }

        res.status(201).json(notification);
    } catch (error) {
        console.error('Create Notification Error:', error);
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
