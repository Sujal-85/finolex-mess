const mongoose = require('mongoose');

const studentSchema = new mongoose.Schema({
    name: { type: String, required: true },
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

    // Payment & Fine Tracking
    paymentStatus: { type: String, enum: ['paid', 'pending', 'overdue'], default: 'pending' },
    paymentDueDate: { type: Date, default: () => new Date(new Date().getFullYear(), new Date().getMonth(), 10) }, // Default to 10th of current month
    fineAmount: { type: Number, default: 0 },
    monthlyFee: { type: Number, default: 3500 },
    lastPaymentResetDate: { type: Date }, // To track when we last renewed the month

    createdAt: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('Student', studentSchema);
