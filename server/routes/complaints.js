const express = require('express');
const router = express.Router();
const Complaint = require('../models/Complaint');
const Notification = require('../models/Notification');

// Get all complaints or filter by studentId
router.get('/', async (req, res) => {
    try {
        const { studentId } = req.query;
        let query = {};
        if (studentId) {
            query.studentId = studentId;
        }
        const complaints = await Complaint.find(query).sort({ date: -1 });
        res.json(complaints);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Create complaint
router.post('/', async (req, res) => {
    const complaint = new Complaint(req.body);
    try {
        const newComplaint = await complaint.save();
        res.status(201).json(newComplaint);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Update complaint status
router.patch('/:id', async (req, res) => {
    try {
        const complaint = await Complaint.findByIdAndUpdate(req.params.id, req.body, { new: true });

        // Create notification for the student
        if (complaint && req.body.status) {
            const notification = new Notification({
                recipient: complaint.studentId, // Assuming studentId is the User ID
                title: 'Complaint Update',
                message: `Your complaint "${complaint.title}" has been updated to ${complaint.status}.`,
                type: 'urgent'
            });
            await notification.save();
        }

        res.json(complaint);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

module.exports = router;
