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

                    // Check if fully paid
                    // Assuming Total Monthly Fee = 3500 + Fine
                    // Use stored monthlyFee if available, else 3500
                    const totalFee = (student.monthlyFee || 3500) + (student.fineAmount || 0);
                    const remainingDues = Math.max(0, totalFee - student.balance);

                    let title = 'Payment Approved ✅';
                    let description = `Your payment of ₹${transaction.amount} has been approved. New Balance: ₹${student.balance}. Remaining Dues: ₹${remainingDues}.`;

                    if (remainingDues <= 0) {
                        student.paymentStatus = 'paid';
                        student.fineAmount = 0; // Clear fines if fully paid? Or keep record? Usually clear or reset. 
                        // Let's clear fine if paid logic implies 'settled'
                        // student.fineAmount = 0; 

                        title = 'Payment Done Thank You! 🎉';
                        description = 'Payment is done thank you. Your mess fees are fully paid.';
                    } else {
                        student.paymentStatus = 'pending'; // Still pending if partial
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
