const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema({
    name: { type: String, required: true },
    description: { type: String },
    price: { type: Number, required: true },
    category: { type: String, required: true }, // e.g., Snacks, General
    mealType: { type: String, required: true }, // e.g., breakfast, lunch, dinner
    day: { type: String, required: true }, // e.g., Monday, Tuesday
    isAvailable: { type: Boolean, default: true },
    image: { type: String }, // URL to image
    isVeg: { type: Boolean, default: true },
    calories: { type: Number },
    days: { type: [String] } // Keeping for backward compatibility if needed, but 'day' is primary now
});

module.exports = mongoose.model('MenuItem', menuItemSchema);
