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

module.exports = router;
