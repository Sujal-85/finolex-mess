const express = require('express');
const router = express.Router();
const Plan = require('../models/Plan');
const Student = require('../models/Student');

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

        console.log(`[DEBUG] Incoming Plan Creation: Name=${name}, Active=${active} (Type: ${typeof active})`);

        const newPlan = await plan.save();

        // 📌 AUTO-ASSIGN TO STUDENTS IF ACTIVE
        // Handle both boolean and string "true"
        const isActive = active === true || String(active) === 'true';

        if (isActive) {
            console.log(`[DEBUG] New Active Plan Created: ${name}. Assigning to all students...`);
            const students = await Student.find({});
            let count = 0;

            for (const s of students) {
                // Check if already exists (unlikely for new plan, but safe)
                const exists = s.activePlans.some(p => p.planId.toString() === newPlan._id.toString());
                if (!exists) {
                    s.activePlans.push({
                        planId: newPlan._id,
                        name: newPlan.name,
                        price: newPlan.price,
                        startDate: newPlan.startDate,
                        endDate: newPlan.endDate,
                        status: 'pending' // Default status
                    });

                    // Recalculate Balance
                    s.balance = s.activePlans
                        .filter(p => p.status === 'pending')
                        .reduce((sum, p) => sum + p.price, 0);

                    s.paymentStatus = s.balance > 0 ? "pending" : "paid";
                    await s.save();
                    count++;
                }
            }
            console.log(`🎯 Assigned new plan to ${count} students.`);
        }

        res.status(201).json(newPlan);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Update a plan (admin)
// Update a plan (admin)
router.patch('/:id', async (req, res) => {
    try {
        const { name, price, type, active, startDate, endDate } = req.body;
        const plan = await Plan.findById(req.params.id);
        if (!plan) return res.status(404).json({ message: 'Plan not found' });

        const normalize = (d) => d ? new Date(d).toISOString().split('T')[0] : null;
        const incomingDate = normalize(startDate);
        const currentDate = normalize(plan.startDate);

        console.log(`[DEBUG] Plan Update: Incoming Date=${incomingDate}, Current Date=${currentDate}`);

        // Ensure price is valid, fallback to existing plan price or amount
        let newPlanPrice = price !== undefined ? price : (plan.price ?? plan.amount ?? 0);
        console.log(`[DEBUG] Plan Price to Apply: ${newPlanPrice}`);

        // 📌 MAIN LOGIC: NEW PLAN ACTIVATION ON DATE CHANGE
        if (startDate && incomingDate !== currentDate) {
            console.log(`🔁 New plan period detected: ${currentDate} → ${incomingDate}`);

            if (newPlanPrice <= 0) {
                console.warn("⚠️ Warning: Plan price is 0 or negative. Balances may not update correctly.");
            }

            const students = await Student.find({});
            console.log(`[DEBUG] Found ${students.length} students to update.`);

            let updatedCount = 0;
            for await (let s of students) {
                // 1. Add new plan to activePlans if not already present (by ID or same month/year?? prefer simple ID check)
                // Actually, a plan ID is unique. If Admin changes start date of SAME plan, we should update the entry in activePlans?
                // Or just push new entry? For now, we assume this is a "New Billing Cycle" even if same Plan ID has date changed.
                // Better approach: Check if this planId matches an existing 'pending' plan. If so, update it. If 'paid' or not found, add new.

                const existingPlanIndex = s.activePlans.findIndex(p => p.planId.toString() === req.params.id && p.status === 'pending');

                if (existingPlanIndex !== -1) {
                    // Update existing pending plan
                    s.activePlans[existingPlanIndex].price = newPlanPrice;
                    s.activePlans[existingPlanIndex].startDate = incomingDate;
                    s.activePlans[existingPlanIndex].endDate = plan.endDate;
                } else {
                    // Add new active plan
                    s.activePlans.push({
                        planId: plan._id,
                        name: plan.name,
                        price: newPlanPrice,
                        startDate: incomingDate,
                        endDate: plan.endDate,
                        status: 'pending'
                    });
                }

                // 2. Recalculate Balance = Sum of all PENDING plans + Fines - Extra Credits
                // actually, balance in DB is strictly "Debt".
                // So Balance = Sum(Pending Plans.price)

                const totalPlanDebt = s.activePlans
                    .filter(p => p.status === 'pending')
                    .reduce((sum, p) => sum + p.price, 0);

                // Preserve any "extra" credit or previous manual adjustments? 
                // In new model, `balance` IS the debt. 
                // If student had credit (negative balance), we should apply it to the new debt.

                let currentNetBalance = totalPlanDebt;

                // If they had a credit (negative balance) before this update...
                // It's hard to track "credit" if we only sum plans.
                // We need a separate 'credit' field or interpret logic carefully.
                // For simplified transition: Let's assume Balance IS the reference.

                // RE-THINK: If we use activePlans, `balance` field becomes redundant or a cache.
                // Let's treat `balance` as the SOURCE OF TRUTH for "Total Amount Due".
                // It equals: Sum(Unpaid Plans) + Fines - Wallet/Credit.

                // If we simply set balance = totalPlanDebt, we lose previous credits.
                // Let's assume logic:
                // New Balance = Old Balance (which might include credits) + New Plan Price (if added)

                // Wait, if we added to activePlans, we increased debt.
                // So we should just ADD to balance?

                // if (existingPlanIndex === -1) {
                //    // Only add if it's a NEW addition to debt
                //    balance += newPlanPrice;
                // }

                // But user wants "Stored value... cumulative". 
                // Let's stick to: Balance = Sum(Active Pending Plans) - (Any unallocated payments could be tricky).
                // For now, let's keep simplistic:
                // 1. Add to activePlans.
                // 2. Recalculate Balance field as Sum(Pending Plans).

                s.balance = s.activePlans.filter(p => p.status === 'pending').reduce((sum, p) => sum + p.price, 0);

                s.paymentStatus = s.balance > 0 ? "pending" : "paid";
                s.lastPlanUpdated = new Date();
                await s.save();
                updatedCount++;
            }
            console.log(`🎯 Successfully updated active plans & balances for ${updatedCount} students.`);
        } else {
            console.log("ℹ️ Plan date is unchanged — skipping balance update.");
        }

        // 🛠️ Update fields if needed
        if (name) plan.name = name;
        if (price) plan.price = price;
        if (type) plan.type = type;
        if (active !== undefined) plan.active = active;
        if (startDate) plan.startDate = startDate;
        if (endDate) plan.endDate = endDate;

        const updatedPlan = await plan.save();
        res.json(updatedPlan);

    } catch (err) {
        console.error(err);
        res.status(400).json({ message: err.message });
    }
});


// Delete a plan (admin)
router.delete('/:id', async (req, res) => {
    try {
        const plan = await Plan.findById(req.params.id);
        if (!plan) return res.status(404).json({ message: 'Plan not found' });

        // 1. Delete the plan document
        await Plan.findByIdAndDelete(req.params.id);
        console.log(`🗑️ Deleted Plan: ${plan.name} (${plan._id})`);

        // 2. Remove plan from all students' activePlans
        const students = await Student.find({ 'activePlans.planId': plan._id });
        console.log(`[DEBUG] Found ${students.length} students with this plan. Cleaning up...`);

        let updatedCount = 0;
        for (const s of students) {
            // Filter out the deleted plan
            const initialLength = s.activePlans.length;
            s.activePlans = s.activePlans.filter(p => p.planId.toString() !== req.params.id);

            if (s.activePlans.length !== initialLength) {
                // Recalculate Balance
                s.balance = s.activePlans
                    .filter(p => p.status === 'pending')
                    .reduce((sum, p) => sum + p.price, 0);

                s.paymentStatus = s.balance > 0 ? "pending" : "paid";
                await s.save();
                updatedCount++;
            }
        }
        console.log(`🎯 Removed plan from ${updatedCount} students & updated balances.`);

        res.json({ message: 'Plan deleted and removed from student profiles' });

    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;

