const express = require('express');
const router = express.Router();
const Transaction = require('../models/Transaction');
const Student = require('../models/Student');

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
        const Notification = require('../models/Notification');
        const notification = new Notification({
            userId: studentId,
            title: 'Payment Submitted ⏳',
            description: `Your payment of ₹${amount} is pending approval.`,
            type: 'payment',
            isNew: true
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
                    // Update Balance
                    student.balance += transaction.amount;
                    await student.save();

                    // Create Notification
                    const Notification = require('../models/Notification');
                    const remainingDues = Math.max(0, 3500 - student.balance);

                    const notification = new Notification({
                        userId: student._id,
                        title: 'Payment Approved ✅',
                        description: `Your payment of ₹${transaction.amount} has been approved. New Balance: ₹${student.balance}. Remaining Dues: ₹${remainingDues}.`,
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
