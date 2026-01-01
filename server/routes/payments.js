const express = require('express');
const router = express.Router();
const Transaction = require('../models/Transaction');
const Student = require('../models/Student');
const Notification = require('../models/Notification');

// Manual UPI Payment
router.post('/manual-upi', async (req, res) => {
    try {
        const { studentId, amount, receiptUrl, upiId } = req.body;

        // Save Transaction
        const transaction = new Transaction({
            studentId,
            amount,
            status: 'Pending',
            receiptUrl,
            paymentMethod: 'UPI_Manual',
            upiId
        });
        await transaction.save();

        // Create Notification for Submission
        const notification = new Notification({
            userId: studentId,
            title: 'Payment Submitted ⏳',
            description: `Your payment of ₹${amount} is pending approval.`,
            type: 'payment'
        });
        await notification.save();

        // Note: Balance is NOT updated here. It will be updated by admin upon approval.

        res.json({ message: 'Payment submitted for review', status: 'Pending' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Get Transaction History
router.get('/history/:studentId', async (req, res) => {
    try {
        const transactions = await Transaction.find({ studentId: req.params.studentId }).sort({ date: -1 });
        res.json(transactions);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
});

// Update Transaction Status (Approval)
// Import Plan
const Plan = require('../models/Plan');

// Helper to get active plan price
async function getActivePlanPrice() {
    try {
        const plan = await Plan.findOne({ active: true });
        return plan ? plan.price : 3500;
    } catch (e) {
        return 3500;
    }
}

router.put('/update-status', async (req, res) => {
    try {
        const { transactionId, status } = req.body;
        const transaction = await Transaction.findById(transactionId);

        if (!transaction) {
            return res.status(404).json({ message: 'Transaction not found' });
        }

        // Only process if status is changing
        if (transaction.status !== status) {
            transaction.status = status;
            await transaction.save();

            // If approved, update student balance and notify
            if (status === 'Success') {
                const student = await Student.findById(transaction.studentId);
                if (student) {
                    // Update Balance (Logic: Balance is DEBT. Payment reduces DEBT.)
                    // student.balance -= transaction.amount; // Old logic? No, balance was debt.
                    // Wait, previous logic was `student.balance += transaction.amount` which implies balance was "Amount Paid" or "Wallet".
                    // BUT we just switched to "Balance = Debt".
                    // So if Balance is Debt (e.g., 3500), and I pay 3500, Balance should become 0.
                    // So: student.balance -= transaction.amount;

                    // HOWEVER, we are now using `activePlans` as source of truth.
                    // We need to allocate this payment to the oldest 'pending' plans.

                    let remainingPayment = transaction.amount;

                    // Sort pending plans by date (oldest first)
                    if (student.activePlans && student.activePlans.length > 0) {
                        const pendingPlans = student.activePlans
                            .filter(p => p.status === 'pending')
                            .sort((a, b) => new Date(a.startDate) - new Date(b.startDate));

                        for (let plan of pendingPlans) {
                            if (remainingPayment >= plan.price) {
                                plan.status = 'paid';
                                remainingPayment -= plan.price;
                                console.log(`[Payment] Cleared plan: ${plan.name} (${plan.price})`);
                            } else {
                                // Partial payment? 
                                // For now, we only mark as paid if fully covered?
                                // Or do we enable partial status?
                                // Let's simplify: Only mark 'paid' if fully covered.
                                // Remaining payment just reduces the "Balance" field visually?
                                // But next time we recalc balance index, it will sum active plans.
                                // FIX: We need a "paidAmount" field in activePlans?
                                // OR: Just trust `balance`.

                                // If we rely on valid 'activePlans' status for reports, we MUST mark them paid.
                                // If payment is partial, plan remains pending.
                                break;
                            }
                        }
                    }

                    // Recalculate Balance
                    // Balance = (Sum of Pending Plans) + Fines - (Any Unallocated Credit/Partial Payments)
                    // This is getting complex.
                    // Lets define: Balance = Current Outstanding Debt.

                    // Simple approach for now:
                    // 1. Reduce Balance by Amount.
                    // 2. If Balance <= 0, mark ALL as paid? No, that's risky.

                    // Better approach:
                    // 1. Try to clear plans.
                    // 2. Recalculate Balance = expectedSumOfPending - excessPayment

                    const totalPendingDebt = student.activePlans
                        .filter(p => p.status === 'pending')
                        .reduce((sum, p) => sum + p.price, 0);

                    // If we cleared plans, they are no longer in this sum.
                    // If we have remainingPayment (partial for next plan or extra), subtract it.

                    student.balance = totalPendingDebt - remainingPayment;

                    // Check if fully paid
                    const remainingDues = student.balance;

                    let title = 'Payment Approved ✅';
                    let description = `Your payment of ₹${transaction.amount} has been approved. Remaining Dues: ₹${remainingDues.toFixed(2)}.`;

                    if (remainingDues <= 0) {
                        student.paymentStatus = 'paid';
                        student.fineAmount = 0; // Clear fines

                        title = 'Payment Done Thank You! 🎉';
                        description = 'Payment is done thank you. Your mess fees are fully paid.';

                        // CLEANUP: Remove "Pending Payment" and "Fine" notifications
                        try {
                            await Notification.deleteMany({
                                userId: student._id,
                                title: { $in: ['Payment Pending ⚠️', 'Daily Fine Applied'] }
                            });
                        } catch (err) {
                            console.error('Error removing stale notifications:', err);
                        }
                    } else {
                        student.paymentStatus = 'pending';
                    }

                    await student.save();

                    // Create Notification
                    const Notification = require('../models/Notification');

                    const notification = new Notification({
                        userId: student._id,
                        title: title,
                        description: description,
                        type: 'payment'
                    });
                    await notification.save();
                }
            }
        }

        res.json({ message: 'Transaction status updated', transaction });
    } catch (error) {
        console.error('Update Status Error:', error);
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
