const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
    name: { type: String, required: true },
    rollNo: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    phone: { type: String },
    password: { type: String, required: true }, // Should be hashed
    dob: { type: Date },
    balance: { type: Number, default: 0 },
    profileImage: {
        type: String,
        default: ''
    },
    hostelDetails: {
        isHostelite: { type: Boolean, default: false },
        hostelName: { type: String, default: '' },
        roomNo: { type: String, default: '' }
    },
    isEmailVerified: { type: Boolean, default: false },
    isPhoneVerified: { type: Boolean, default: false },
    fcmToken: { type: String }, // For push notifications
    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Student', studentSchema);
