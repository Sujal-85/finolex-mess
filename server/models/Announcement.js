const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: { type: String, required: true }, // Short summary
    content: { type: String }, // Full details
    type: { type: String, enum: ['general', 'urgent', 'event'], default: 'general' },
    date: { type: Date, default: Date.now },
    isActive: { type: Boolean, default: true }
});

module.exports = mongoose.model('Announcement', announcementSchema);
