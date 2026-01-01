const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Student = require('../models/Student');
const Plan = require('../models/Plan');

const VALID_PLAN_ID = '693295ba9ad7ad6d0314ebd7'; // The original Main Plan
const INVALID_PLAN_IDS = [
    '69565efaf7a97d8a6f06846e', // "Standard Mess Plan" (Debug)
    '6956594e028677fc509e9bfc'  // Duplicate "Main Plan"
];

const cleanup = async () => {
    try {
        if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI missing');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');

        // 1. Delete Invalid Plans
        const deleteResult = await Plan.deleteMany({ _id: { $in: INVALID_PLAN_IDS } });
        console.log(`Deleted ${deleteResult.deletedCount} invalid plans.`);

        // 2. Fetch Valid Plan Details
        const validPlan = await Plan.findById(VALID_PLAN_ID);
        if (!validPlan) throw new Error('Valid active plan not found!');

        console.log(`Targeting Valid Plan: ${validPlan.name} (${validPlan.price})`);

        // 3. Update Students
        const students = await Student.find({});
        console.log(`Processing ${students.length} students...`);

        for (const student of students) {
            let modified = false;

            // A. Remove invalid plans from activePlans
            if (student.activePlans && student.activePlans.length > 0) {
                const checkLen = student.activePlans.length;
                student.activePlans = student.activePlans.filter(p => {
                    // Check if planId matches invalid IDs
                    const pId = p.planId?.toString();
                    return !INVALID_PLAN_IDS.includes(pId);
                });

                if (student.activePlans.length !== checkLen) {
                    console.log(` - Removed invalid plans for ${student.name}`);
                    modified = true;
                }
            }

            // B. Ensure they have the VALID plan
            // Check if they already have the valid plan ID
            const hasValidPlan = student.activePlans.some(p => p.planId?.toString() === VALID_PLAN_ID);

            if (!hasValidPlan) {
                console.log(` - Adding valid plan to ${student.name}`);
                student.activePlans.push({
                    planId: validPlan._id,
                    name: validPlan.name,
                    price: validPlan.price,
                    startDate: validPlan.startDate,
                    endDate: validPlan.endDate,
                    status: 'pending',
                    addedAt: new Date()
                });
                modified = true;
            }

            // C. Recalculate Balance
            // ONLY if we modified the plans, or to be safe, always sync balance to pending plans?
            // Let's sync balance to be safe, as previous scripts might have messed it up.
            const totalPending = student.activePlans
                .filter(p => p.status === 'pending')
                .reduce((sum, p) => sum + p.price, 0);

            if (student.balance !== totalPending) {
                console.log(` - Correcting balance for ${student.name}: ${student.balance} -> ${totalPending}`);
                student.balance = totalPending;
                modified = true;
            }

            if (modified) {
                await student.save();
                console.log(`Saved updates for ${student.name}`);
            }
        }

        console.log('Cleanup Complete!');

    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

cleanup();
