const express = require('express');
const router = express.Router();
const Announcement = require('../models/Announcement');
const Notification = require('../models/Notification');

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
            userId: null, // Global notification
            title: `New Announcement: ${newAnnouncement.title}`,
            description: newAnnouncement.description,
            type: 'news'
        });
        await notification.save();

        res.status(201).json(newAnnouncement);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

module.exports = router;
