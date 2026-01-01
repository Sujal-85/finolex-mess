const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Student = require('../models/Student');
const Plan = require('../models/Plan');

const syncPlans = async () => {
    try {
        if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI missing');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');

        // 1. Fetch ALL Active Plans from DB
        const dbPlans = await Plan.find({ active: true });
        console.log(`Found ${dbPlans.length} active plans in DB:`);
        dbPlans.forEach(p => console.log(` - ${p.name} (${p.price})`));

        if (dbPlans.length === 0) {
            console.warn('WARNING: No active plans found in DB. Students will have 0 plans.');
        }

        const students = await Student.find({});
        console.log(`Syncing ${students.length} students...`);

        for (const student of students) {
            // We want to REPLACE the student's activePlans with the dbPlans.
            // But if they have already paid for one of them, we should preserve that status?
            // The user said "fetch from the database", implying the structure comes from there.
            // Since we are "fixing" it, let's assume all are 'pending' unless we can match by ID.

            const newActivePlans = [];
            let modified = false;

            for (const dbPlan of dbPlans) {
                // Check if student already has this plan (by ID)
                // We use .equals for ObjectId comparison or string conversion
                const existing = student.activePlans.find(p =>
                    p.planId && p.planId.toString() === dbPlan._id.toString()
                );

                if (existing) {
                    // Keep existing status (e.g. if they paid part of it, though structure is simple)
                    newActivePlans.push(existing);
                } else {
                    // Add new
                    console.log(`   + Adding "${dbPlan.name}" to ${student.name}`);
                    newActivePlans.push({
                        planId: dbPlan._id,
                        name: dbPlan.name,
                        price: dbPlan.price,
                        startDate: dbPlan.startDate,
                        endDate: dbPlan.endDate,
                        status: 'pending',
                        addedAt: new Date()
                    });
                    modified = true;
                }
            }

            // Check if we removed any (e.g. Special Feast)
            if (student.activePlans.length !== newActivePlans.length) {
                console.log(`   - Removed ${student.activePlans.length - newActivePlans.length} invalid/old plans for ${student.name}`);
                modified = true;
            }

            // Update Plans
            student.activePlans = newActivePlans;

            // Recalculate Balance
            const totalPending = student.activePlans
                .filter(p => p.status === 'pending')
                .reduce((sum, p) => sum + p.price, 0);

            if (student.balance !== totalPending) {
                console.log(`   * Adjusted balance for ${student.name}: ${student.balance} -> ${totalPending}`);
                student.balance = totalPending;
                modified = true;
            }

            if (modified) {
                await student.save();
                // console.log(`     Saved.`);
            }
        }

        console.log('Sync Complete!');

    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

syncPlans();
