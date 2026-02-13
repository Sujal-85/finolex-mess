const express = require('express');
const router = express.Router();
const Transaction = require('../models/Transaction');
const Student = require('../models/Student');
const Notification = require('../models/Notification');
const Razorpay = require('razorpay');
const crypto = require('crypto');

// Razorpay Instance
const razorpay = new Razorpay({
    key_id: 'rzp_test_SBN8qqqrYVLeS7',
    key_secret: 'GrJwhFudpL4Xu8PCfTmvbvLt'
});

// Helper to approve transaction
async function approveTransaction(transaction, studentId, amount) {
    const student = await Student.findById(studentId);
    if (!student) return;

    student.balance -= amount;

    if (student.activePlans && student.activePlans.length > 0) {
        let remainingPayment = amount;
        const pendingPlans = student.activePlans
            .filter(p => p.status === 'pending')
            .sort((a, b) => new Date(a.startDate) - new Date(b.startDate));

        for (let plan of pendingPlans) {
            if (remainingPayment >= plan.price) {
                plan.status = 'paid';
                remainingPayment -= plan.price;
            } else {
                break;
            }
        }
    }

    if (student.balance <= 0) {
        student.paymentStatus = 'paid';
        try {
            await Notification.deleteMany({
                recipient: student._id,
                title: { $in: ['Payment Pending ⚠️', 'Daily Fine Applied'] }
            });
        } catch (err) {
            console.error('Error removing stale notifications:', err);
        }
    } else {
        student.paymentStatus = 'pending';
    }

    await student.save();

    const title = student.balance <= 0 ? 'Payment Done Thank You! 🎉' : 'Payment Approved ✅';
    const description = student.balance <= 0
        ? 'Payment is done thank you. Your mess fees are fully paid.'
        : `Your payment of ₹${amount} has been approved. Remaining Dues: ₹${student.balance.toFixed(2)}.`;

    const notification = new Notification({
        recipient: student._id,
        title: title,
        message: description,
        type: 'payment'
    });
    await notification.save();
}



// Create Razorpay Order
router.post('/create-order', async (req, res) => {
    try {
        const { amount } = req.body;
        const options = {
            amount: amount * 100, // amount in the smallest currency unit (paise)
            currency: "INR",
            receipt: "receipt_" + Date.now(),
        };

        const order = await razorpay.orders.create(options);
        res.json(order);
    } catch (error) {
        console.error('Create Order Error:', error);
        res.status(500).json({ message: error.message });
    }
});

// Verify Razorpay Payment
router.post('/verify-payment', async (req, res) => {
    try {
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature, studentId, amount } = req.body;

        const generated_signature = crypto
            .createHmac('sha256', 'GrJwhFudpL4Xu8PCfTmvbvLt')
            .update(razorpay_order_id + "|" + razorpay_payment_id)
            .digest('hex');

        if (generated_signature === razorpay_signature) {
            // Payment Success
            const transaction = new Transaction({
                studentId,
                amount,
                status: 'Success',
                receiptUrl: '', // Can be updated if needed
                paymentMethod: 'Razorpay',
                upiId: razorpay_payment_id // Storing payment ID here
            });
            await transaction.save();

            await approveTransaction(transaction, studentId, amount);

            res.json({ message: 'Payment verified successfully', status: 'Success' });
        } else {
            res.status(400).json({ message: 'Invalid Signature', status: 'Failed' });
        }
    } catch (error) {
        console.error('Verify Payment Error:', error);
        res.status(500).json({ message: error.message });
    }
});

// Manual UPI Payment
router.post('/manual-upi', async (req, res) => {
    try {
        const { studentId, amount, receiptUrl, upiId } = req.body;
        const isDirect = upiId === 'UPI_INTENT';

        // Save Transaction
        const transaction = new Transaction({
            studentId,
            amount,
            status: isDirect ? 'Success' : 'Pending',
            receiptUrl,
            paymentMethod: isDirect ? 'UPI_Direct' : 'UPI_Manual',
            upiId
        });
        await transaction.save();

        if (isDirect) {
            await approveTransaction(transaction, studentId, amount);
            return res.json({ message: 'Payment successful and recorded', status: 'Success' });
        }

        // Create Notification for Submission (QR Scan only)
        const notification = new Notification({
            recipient: studentId,
            title: 'Payment Submitted ⏳',
            message: `Your payment of ₹${amount} is pending approval.`,
            type: 'payment'
        });
        await notification.save();

        res.json({ message: 'Payment submitted for review', status: 'Pending' });
    } catch (error) {
        console.error('Manual UPI Error:', error);
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
                await approveTransaction(transaction, transaction.studentId, transaction.amount);
            }
        }

        res.json({ message: 'Transaction status updated', transaction });
    } catch (error) {
        console.error('Update Status Error:', error);
        res.status(500).json({ message: error.message });
    }
});

module.exports = router;
