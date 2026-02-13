const mongoose = require('mongoose');

const dailyTrackingSchema = new mongoose.Schema({
    date: {
        type: Date,
        required: true,
        unique: true
    },
    stats: {
        breakfast: { type: Number, default: 0 },
        lunch: { type: Number, default: 0 },
        dinner: { type: Number, default: 0 }
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('DailyTracking', dailyTrackingSchema);
