const express = require('express');
const router = express.Router();
const Feedback = require('../models/Feedback');

// Submit Feedback
router.post('/', async (req, res) => {
    try {
        const { studentId, type, rating, description, images } = req.body;

        const feedback = new Feedback({
            studentId,
            type,
            rating,
            description,
            images
        });

        const newFeedback = await feedback.save();
        res.status(201).json(newFeedback);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Get all feedback (for admin/testing)
router.get('/', async (req, res) => {
    try {
        const feedbacks = await Feedback.find().populate('studentId', 'name rollNo');
        res.json(feedbacks);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Get feedback by student
router.get('/student/:studentId', async (req, res) => {
    try {
        const feedbacks = await Feedback.find({ studentId: req.params.studentId });
        res.json(feedbacks);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
