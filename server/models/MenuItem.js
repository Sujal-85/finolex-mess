const mongoose = require('mongoose');

const menuItemSchema = new mongoose.Schema({
    name: { type: String, required: true },
    description: { type: String },
    price: { type: Number, required: true },
    category: { type: String, enum: ['breakfast', 'lunch', 'dinner', 'snacks', 'beverages'], required: true },
    isAvailable: { type: Boolean, default: true },
    image: { type: String }, // URL to image
    isVeg: { type: Boolean, default: true },
    calories: { type: Number }
});

module.exports = mongoose.model('MenuItem', menuItemSchema);
