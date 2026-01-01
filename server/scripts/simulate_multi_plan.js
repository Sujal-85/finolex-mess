const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Student = require('../models/Student');

const addSecondPlan = async () => {
    try {
        if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI missing');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');

        // Target a specific student (or all, but let's do all for simplicity of testing)
        // Ideally we filter by email if we knew it, but updating all is fine for dev.
        const students = await Student.find({});
        console.log(`Processing ${students.length} students...`);

        const secondPlan = {
            planId: new mongoose.Types.ObjectId(), // Fake ID
            name: 'Special Feast',
            price: 500,
            startDate: new Date(),
            endDate: new Date(new Date().setDate(new Date().getDate() + 7)),
            status: 'pending',
            addedAt: new Date()
        };

        for (const student of students) {
            // Check if they already have a second plan to avoid duplicates
            if (student.activePlans.length < 2) {
                console.log(`Adding "Special Feast" to ${student.name}`);
                student.activePlans.push(secondPlan);

                // Recalculate balance
                const totalPending = student.activePlans
                    .filter(p => p.status === 'pending')
                    .reduce((sum, p) => sum + p.price, 0);

                student.balance = totalPending;
                await student.save();
            } else {
                console.log(`Skipping ${student.name}, already has active plans.`);
            }
        }

        console.log('Done! Added second plan.');

    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

addSecondPlan();
