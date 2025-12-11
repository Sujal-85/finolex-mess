const mongoose = require('mongoose');

const planSchema = new mongoose.Schema({
    name: { type: String, required: true },
    price: { type: Number, required: true },
    type: { type: String, default: 'basic' },
    active: { type: Boolean, default: true },
    features: { type: Array, default: [] },
    createdAt: { type: Date, default: Date.now }
});

// Explicitly use 'plans' (or 'plan' depending on user DB, user said "plan collection" but usually Mongoose pluralizes.
// If valid collection is 'plans' (standard), let's stick to standard or 'plan' if confirmed.
// User said "plan collection is already there". I will map to 'plan' to be safe based on previous turn, or 'plans'.
// The screenshot shows "_id" which usually implies Mongoose.
// Let's assume 'plan' singular name in `mongoose.model` might define collection as 'plans'.
// Explicitly use 'plans' to match existing collection with price: 4500
module.exports = mongoose.model('plans', planSchema, 'plans');
