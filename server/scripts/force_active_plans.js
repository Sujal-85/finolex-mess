const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Student = require('../models/Student');
const Plan = require('../models/Plan');

const connectDB = async () => {
    try {
        if (!process.env.MONGODB_URI) {
            throw new Error('MONGODB_URI is not defined in .env');
        }
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');
    } catch (err) {
        console.error('Connection Error:', err);
        process.exit(1);
    }
};

const forceAddPlan = async () => {
    await connectDB();

    try {
        // 1. Get the current active plan details
        // Note: Schema might use 'active' or 'isActive'. Checking both or preferring 'active' based on user image.
        let currentPlan = await Plan.findOne({ active: true });

        if (!currentPlan) {
            console.log('No active plan found. Creating one...');
            currentPlan = await Plan.create({
                name: 'Standard Mess Plan',
                price: 3500,
                amount: 3500, // Legacy support
                startDate: new Date(),
                endDate: new Date(new Date().setDate(new Date().getDate() + 30)),
                active: true,
                features: ['Breakfast', 'Lunch', 'Dinner']
            });
            console.log('Created new active plan.');
        }

        console.log(`Using Active Plan: ${currentPlan.name} (${currentPlan.price})`);

        // 2. Find all students
        const students = await Student.find({});
        console.log(`Processing ${students.length} students...`);

        for (const student of students) {
            console.log(`Checking Student: ${student.name} (${student.email})`);

            // Check if they already have *any* plan in activePlans array (even if empty structure)
            const hasPlan = student.activePlans && student.activePlans.length > 0;

            if (!hasPlan) {
                console.log(` -> No active plans. Adding "${currentPlan.name}"...`);

                // Construct the plan object
                const newPlan = {
                    planId: currentPlan._id,
                    name: currentPlan.name || 'Monthly Mess',
                    price: currentPlan.price || 3500,
                    startDate: currentPlan.startDate || new Date(),
                    endDate: currentPlan.endDate || new Date(new Date().setDate(new Date().getDate() + 30)),
                    status: 'pending', // Default to pending
                    addedAt: new Date()
                };

                // Initialize array if undefined
                if (!student.activePlans) {
                    student.activePlans = [];
                }

                student.activePlans.push(newPlan);

                // Recalculate balance based on active plans
                const totalPending = student.activePlans
                    .filter(p => p.status === 'pending')
                    .reduce((sum, p) => sum + p.price, 0);

                student.balance = totalPending;

                await student.save();
                console.log(` -> Updated! New Balance: ${student.balance}`);
            } else {
                console.log(' -> Already has active plans. Inspecting first plan:');
                if (student.activePlans.length > 0) {
                    console.log(JSON.stringify(student.activePlans[0], null, 2));
                }
            }
        }

        console.log('Done!');
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await mongoose.disconnect();
    }
};

forceAddPlan();
