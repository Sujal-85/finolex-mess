const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Plan = require('../models/Plan');

const checkPlans = async () => {
    try {
        if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI missing');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');

        const plans = await Plan.find({});
        console.log(`\nFound ${plans.length} total plans:\n`);

        plans.forEach(p => {
            console.log(`[${p._id}] Name: "${p.name}", Price: ${p.price}, Active: ${p.active || p.isActive}, Created: ${p.createdAt}`);
        });

    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

checkPlans();
