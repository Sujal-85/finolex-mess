const mongoose = require('mongoose');
const path = require('path');
const Plan = require('../models/Plan');
const Student = require('../models/Student');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
    console.error("❌ MONGODB_URI not found in .env file!");
    process.exit(1);
}

const debugPlanUpdate = async () => {
    try {
        console.log("🔌 Connecting to MongoDB...");
        await mongoose.connect(MONGODB_URI);
        console.log("✅ Connected.");

        // 1. Fetch Active Plan
        const plan = await Plan.findOne({ active: true });
        if (!plan) {
            console.error("❌ No active plan found!");
            return;
        }
        console.log(`\n📋 Current Active Plan: ${plan.name}`);
        console.log(`   ID: ${plan._id}`);
        console.log(`   StartDate: ${plan.startDate}`);
        console.log(`   Price: ${plan.price}, Amount: ${plan.amount}`);

        // 2. Simulate Input (Changing StartDate to Tomorrow)
        const currentStartDate = plan.startDate ? new Date(plan.startDate).toISOString().split('T')[0] : 'N/A';

        // Simulating a NEW start date (different from current)
        const incomingDate = new Date();
        incomingDate.setDate(incomingDate.getDate() + 1); // Tomorrow
        const incomingDateStr = incomingDate.toISOString().split('T')[0];

        // Determine Prie
        let newPlanPrice = plan.price ?? plan.amount ?? 0;

        console.log(`\n🔄 Simulating Update:`);
        console.log(`   Current Date: ${currentStartDate}`);
        console.log(`   Incoming Date: ${incomingDateStr}`);
        console.log(`   Price to Apply: ${newPlanPrice}`);

        if (currentStartDate === incomingDateStr) {
            console.log("⚠️ Dates are same. Logic would SKIP update.");
        } else {
            console.log("✅ Dates differ. Logic would TRIGGER update.");
        }

        if (newPlanPrice <= 0) {
            console.warn("⚠️ CRITICAL: Plan price is <= 0. Balances will not increase!");
        }

        // 3. Check Students
        const students = await Student.find({});
        console.log(`\n👥 Found ${students.length} students.`);

        let wouldUpdateCount = 0;
        const sampleSize = 5;
        console.log(`   Showing first ${sampleSize} simulations:`);

        for (let i = 0; i < students.length; i++) {
            const s = students[i];
            let balance = s.balance || 0;
            let originalBalance = balance;
            let status = "";

            if (balance > 0) {
                balance += newPlanPrice;
                status = "Pending (Increased Debt)";
            } else if (balance === 0) {
                balance = newPlanPrice; // 0 -> Price
                status = "Pending (New Debt)";
            } else if (balance < 0) {
                balance = balance + newPlanPrice;
                status = balance > 0 ? "Pending (Debt)" : "Paid (Still Credit)";
            }

            // APPYING UPDATES
            s.balance = balance;
            s.paymentStatus = balance > 0 ? "pending" : "paid";
            s.lastPlanUpdated = new Date();
            if (i < sampleSize) {
                console.log(`   👤 Student ${s.name || s.email} | Bal: ${originalBalance} -> ${balance} | Status: ${status}`);
            }
            // await s.save(); // Uncomment to save
            await s.save(); // FORCE SAVING NOW
            wouldUpdateCount++;
        }
        console.log(`\n📈 Successfully FORCED updated for ${wouldUpdateCount} students.`);

        // Also update the plan start date to tomorrow to reflect the change
        if (plan) {
            plan.startDate = incomingDate;
            await plan.save();
            console.log("✅ Plan StartDate updated to incoming date.");
        }

    } catch (e) {
        console.error("❌ Error:", e);
    } finally {
        await mongoose.disconnect();
        console.log("🔌 Disconnected.");
    }
};

debugPlanUpdate();
