const mongoose = require('mongoose');

const complaintSchema = new mongoose.Schema({
    studentId: { type: String, required: true }, // Could be a reference to Student model
    title: { type: String, required: true },
    description: { type: String, required: true },
    category: { type: String, enum: ['food', 'service', 'cleanliness', 'other'], default: 'other' },
    status: { type: String, enum: ['pending', 'in_progress', 'resolved'], default: 'pending' },
    date: { type: Date, default: Date.now },
    adminResponse: { type: String },
    images: [{ type: String }], // Array of image URLs
});

module.exports = mongoose.model('Complaint', complaintSchema);
