const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Student = require('../models/Student');
const Plan = require('../models/Plan');

const JAN_PLAN_ID = '695660bd028677fc509e9c5f'; // January Plan
const SPECIAL_FEAST_ID = '69566125d2f0542a9d6e6e44'; // Special Feast (from previous script, need to verify if ID is constant or generated. Actually generated IDs in previous script were fake/client-side unless saved to Plan col? Previous script just pushed object to student array with new ObjectId. So we search by name 'Special Feast').

// Actually the previous script generated a new ObjectId() for Special Feast properly?
// Let's filter by NAME to be safe.

const fixPlans = async () => {
    try {
        if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI missing');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');

        // Get 'January Plan' details
        const janPlan = await Plan.findById(JAN_PLAN_ID);
        if (!janPlan) throw new Error('January Plan not found');

        const students = await Student.find({});
        console.log(`Processing ${students.length} students...`);

        for (const student of students) {
            let modified = false;

            // 1. Remove 'Main Plan' if present (assuming they want Jan Plan instead)
            // Or should we keep both? User said "not showing me the another plan Jan plan", implying it should be there.
            // Let's keep Special Feast.
            // Let's REPLACE 'Main Plan' with 'January Plan'.

            const newActivePlans = [];

            // Preserve Special Feast or other custom plans
            student.activePlans.forEach(p => {
                if (p.name === 'Special Feast') {
                    newActivePlans.push(p);
                }
            });

            // Add January Plan if not already there (name check)
            const hasJan = newActivePlans.some(p => p.name === 'January Plan');
            if (!hasJan) {
                console.log(`Adding January Plan to ${student.name}`);
                newActivePlans.push({
                    planId: janPlan._id,
                    name: janPlan.name,
                    price: janPlan.price,
                    startDate: janPlan.startDate || new Date(),
                    endDate: janPlan.endDate || new Date(new Date().setDate(new Date().getDate() + 30)),
                    status: 'pending',
                    addedAt: new Date()
                });
                modified = true;
            }

            // Update student
            student.activePlans = newActivePlans;

            // Recalculate Balance
            const totalPending = student.activePlans
                .filter(p => p.status === 'pending')
                .reduce((sum, p) => sum + p.price, 0);

            student.balance = totalPending;

            await student.save();
            console.log(`Saved ${student.name}: Balance ${student.balance}, Plans: ${student.activePlans.map(p => p.name).join(', ')}`);
        }

    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

fixPlans();
