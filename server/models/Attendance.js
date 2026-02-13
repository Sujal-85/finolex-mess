const mongoose = require('mongoose');

const mealStatusSchema = new mongoose.Schema({
    status: {
        type: String,
        enum: ['pending', 'present', 'absent', 'not_marked'],
        default: 'not_marked'
    },
    markedAt: {
        type: Date
    },
    verifiedAt: {
        type: Date
    }
}, { _id: false });

const attendanceSchema = new mongoose.Schema({
    student: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Student', // Correct Ref
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    meals: {
        breakfast: { type: mealStatusSchema, default: () => ({}) },
        lunch: { type: mealStatusSchema, default: () => ({}) },
        dinner: { type: mealStatusSchema, default: () => ({}) }
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Compound index to ensure one attendance record per student per day
attendanceSchema.index({ student: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
