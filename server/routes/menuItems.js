const express = require('express');
const router = express.Router();
const MenuItem = require('../models/MenuItem');

// Get all menu items
// Get all menu items (optionally filtered by day)
router.get('/', async (req, res) => {
    try {
        const { day } = req.query;
        let query = {};

        if (day) {
            // Case-insensitive match for the day
            query.day = { $regex: new RegExp(`^${day}$`, 'i') };
        }

        console.log(`Fetching menu for day: ${day || 'All'}, Query:`, JSON.stringify(query));
        const items = await MenuItem.find(query);
        console.log(`Found ${items.length} items`);
        res.json(items);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Add menu item
router.post('/', async (req, res) => {
    const item = new MenuItem(req.body);
    try {
        const newItem = await item.save();
        res.status(201).json(newItem);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Update menu item
router.patch('/:id', async (req, res) => {
    try {
        const item = await MenuItem.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json(item);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Delete menu item
router.delete('/:id', async (req, res) => {
    try {
        await MenuItem.findByIdAndDelete(req.params.id);
        res.json({ message: 'Item deleted' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
