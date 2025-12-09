const express = require('express');
const router = express.Router();
const MenuItem = require('../models/MenuItem');
const Notification = require('../models/Notification');

// Get all menu items
router.get('/', async (req, res) => {
    try {
        let query = {};
        if (req.query.day) {
            query.$or = [
                { day: req.query.day },
                { days: req.query.day }
            ];
        }
        const items = await MenuItem.find(query);
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

        // Notify users about new menu item
        const notification = new Notification({
            title: 'Menu Updated 🍽️',
            description: `${newItem.name} has been added to the ${newItem.category} menu.`,
            type: 'mess',
            isNew: true
        });
        await notification.save();

        res.status(201).json(newItem);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Update menu item
router.patch('/:id', async (req, res) => {
    try {
        const item = await MenuItem.findByIdAndUpdate(req.params.id, req.body, { new: true });

        // Notify users about menu update (Optional: prevent spam by checking if meaningful fields changed)
        const notification = new Notification({
            title: 'Menu Updated 🍽️',
            description: `${item.name} has been updated. Check today's menu!`,
            type: 'mess',
            isNew: true
        });
        await notification.save();

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
