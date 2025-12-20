const mongoose = require('mongoose');

const planSchema = new mongoose.Schema({
    name: { type: String, required: true },
    price: { type: Number, required: true },
    type: { type: String, default: 'monthly' },
    active: { type: Boolean, default: false },
    startDate: { type: Date },
    endDate: { type: Date },
    createdAt: { type: Date, default: Date.now }
});

// For compatibility with any existing code using .amount
planSchema.virtual('amount').get(function () { return this.price; });
planSchema.set('toJSON', { virtuals: true });
planSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('plans', planSchema, 'plans');
