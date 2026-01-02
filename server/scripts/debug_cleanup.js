require('dotenv').config();
const mongoose = require('mongoose');

const Student = require('../models/Student');
const Plan = require('../models/Plan');

async function debugCleanup() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');

        const student = await Student.findOne({ name: 'Mayur Sanjay Garje' });
        if (!student) {
            console.log('Student not found');
            return;
        }

        console.log('Before Cleanup:', student.activePlans.length, 'plans');

        // Logic from scheduler.js / students.js
        const allPlans = await Plan.find({});
        console.log('Total Plans in DB:', allPlans.length);

        const allPlanIds = new Set(allPlans.map(p => p._id.toString()));

        // B. Remove Deleted Plans
        const initialCount = student.activePlans.length;
        console.log('Checking plans against IDs:', Array.from(allPlanIds));

        student.activePlans = student.activePlans.filter(p => {
            const exists = allPlanIds.has(p.planId.toString());
            console.log(`Plan ${p.name} (${p.planId}): Exists? ${exists}`);
            return exists;
        });

        if (student.activePlans.length !== initialCount) {
            console.log(`[Lazy Sync] Removed ${initialCount - student.activePlans.length} deleted plans.`);

            // Recalc
            student.balance = student.activePlans
                .filter(p => p.status === 'pending')
                .reduce((sum, p) => sum + p.price, 0);
            student.paymentStatus = student.balance > 0 ? "pending" : "paid";

            await student.save();
            console.log('Student Saved with Balance:', student.balance);
        } else {
            console.log('No changes made.');
        }

    } catch (err) {
        console.error(err);
    } finally {
        mongoose.disconnect();
    }
}

debugCleanup();
