const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    studentId: { type: String, required: true },
    amount: { type: Number, required: true },
    currency: { type: String, default: 'INR' },
    orderId: { type: String }, // Razorpay Order ID
    paymentId: { type: String }, // Razorpay Payment ID
    signature: { type: String },
    status: { type: String, enum: ['created', 'success', 'failed'], default: 'created' },
    date: { type: Date, default: Date.now },
    items: [{
        menuItemId: { type: mongoose.Schema.Types.ObjectId, ref: 'MenuItem' },
        name: { type: String },
        quantity: { type: Number },
        price: { type: Number }
    }],
    paymentMethod: { type: String } // e.g., 'upi', 'card', 'netbanking'
});

module.exports = mongoose.model('Payment', paymentSchema);
