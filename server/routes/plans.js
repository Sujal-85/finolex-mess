const express = require('express');
const router = express.Router();
const Plan = require('../models/Plan');

// Get active plan
router.get('/', async (req, res) => {
    try {
        const plan = await Plan.findOne({ active: true });
        if (!plan) {
            // Default plan fallback
            const defaultPlan = {
                name: 'Free Plan',
                price: 0,
                type: 'monthly',
                active: true,
                createdAt: new Date(),
            };
            return res.json(defaultPlan);
        }
        // Return plan with price field (fallback to amount if price missing)
        const responsePlan = {
            _id: plan._id,
            name: plan.name,
            price: plan.price ?? plan.amount,
            type: plan.type,
            active: plan.active,
            startDate: plan.startDate,
            endDate: plan.endDate,
            createdAt: plan.createdAt,
        };
        res.json(responsePlan);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Create a plan (admin / seeding)
router.post('/', async (req, res) => {
    try {
        const { name, price, type, active, startDate, endDate } = req.body;
        const plan = new Plan({
            name,
            price,
            type,
            active,
            startDate,
            endDate
        });
        const newPlan = await plan.save();
        res.status(201).json(newPlan);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Update a plan (admin)
router.patch('/:id', async (req, res) => {
    try {
        const { name, price, type, active, startDate, endDate } = req.body;
        const plan = await Plan.findById(req.params.id);
        if (!plan) return res.status(404).json({ message: 'Plan not found' });

        if (name) plan.name = name;
        if (price) plan.price = price;
        if (type) plan.type = type;
        if (active !== undefined) plan.active = active;
        if (startDate) plan.startDate = startDate;
        if (endDate) plan.endDate = endDate;

        const updatedPlan = await plan.save();
        res.json(updatedPlan);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

module.exports = router;

