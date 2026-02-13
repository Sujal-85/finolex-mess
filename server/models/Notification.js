const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
    recipient: { // CHANGED: userId -> recipient
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Student', // It links to Student usually
        required: false // Can be null for global notifications
    },
    title: {
        type: String,
        required: true
    },
    message: { // CHANGED: description -> message
        type: String,
        required: true
    },
    type: {
        type: String,
        enum: ['general', 'mess', 'payment', 'news', 'urgent', 'device_only'],
        default: 'general'
    },
    isRead: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Notification', notificationSchema);
