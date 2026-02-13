const express = require('express');
const router = express.Router();
const Announcement = require('../models/Announcement');
const Notification = require('../models/Notification');
const Student = require('../models/Student');
const admin = require('../services/firebase');

// Get all announcements
router.get('/', async (req, res) => {
    try {
        const announcements = await Announcement.find().sort({ date: -1 });
        res.json(announcements);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Create announcement
router.post('/', async (req, res) => {
    const announcement = new Announcement(req.body);
    try {
        const newAnnouncement = await announcement.save();

        // Create global notification
        const notification = new Notification({
            recipient: null, // Global notification
            title: `New Announcement: ${newAnnouncement.title}`,
            message: newAnnouncement.description,
            type: 'news'
        });
        await notification.save();

        // Send FCM Notification
        const students = await Student.find({}).select('fcmToken');
        const tokens = students.map(s => s.fcmToken).filter(t => t);

        if (tokens.length > 0) {
            const message = {
                notification: {
                    title: 'New Announcement 📢',
                    body: newAnnouncement.title
                },
                tokens: tokens
            };
            admin.messaging().sendEachForMulticast(message).catch(console.error);
        }

        res.status(201).json(newAnnouncement);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

module.exports = router;
