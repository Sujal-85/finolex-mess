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

        const allPlans = await Plan.find({});
        const activeDbPlans = allPlans.filter(p => p.active === true || String(p.active) === 'true');
        const allPlanIds = new Set(allPlans.map(p => p._id.toString()));

        console.log(`Found ${activeDbPlans.length} active plans in DB.`);
        const students = await Student.find({});
        console.log(`Syncing ${students.length} students...`);

        let totalUpdated = 0;

        for (const student of students) {
            let modified = false;

            // A. Add Missing Active Plans
            for (const dbPlan of activeDbPlans) {
                const alreadyHas = student.activePlans.some(p => p.planId.toString() === dbPlan._id.toString());
                if (!alreadyHas) {
                    console.log(`   + Adding "${dbPlan.name}" to ${student.name}`);
                    student.activePlans.push({
                        planId: dbPlan._id,
                        name: dbPlan.name,
                        price: dbPlan.price ?? dbPlan.amount ?? 0,
                        startDate: dbPlan.startDate,
                        endDate: dbPlan.endDate,
                        status: 'pending',
                        addedAt: new Date()
                    });
                    modified = true;
                }
            }

            // B. Remove Deleted Plans
            const initialCount = student.activePlans.length;
            student.activePlans = student.activePlans.filter(p => allPlanIds.has(p.planId.toString()));
            if (student.activePlans.length !== initialCount) {
                console.log(`   - Removed ${initialCount - student.activePlans.length} deleted plans from ${student.name}`);
                modified = true;
            }

            // C. Always Recalculate Balance
            const newBalance = student.activePlans
                .filter(p => p.status === 'pending')
                .reduce((sum, p) => sum + p.price, 0);

            if (student.balance !== newBalance) {
                modified = true;
                student.balance = newBalance;
                student.paymentStatus = student.balance > 0 ? "pending" : "paid";
            }

            if (modified) {
                await student.save();
                totalUpdated++;
            }
        }
        console.log(`Sync Complete! Updated ${totalUpdated} profiles.`);

    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

syncPlans();
