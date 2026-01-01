const express = require('express');
const router = express.Router();
const Student = require('../models/Student');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Secret key (should be in .env)
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

// Import Plan
const Plan = require('../models/Plan');

// Helper to get active plan price
async function getActivePlanPrice() {
    try {
        const plan = await Plan.findOne({ active: true });
        if (plan) {
            return plan.price ?? plan.amount ?? 3500;
        }
        return 3500;
    } catch (e) {
        return 3500;
    }
}

// Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const student = await Student.findOne({ email });
        if (!student) return res.status(404).json({ message: 'Student not found' });

        const isMatch = await bcrypt.compare(password, student.password);
        if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

        // Auto-correct / Read-Repair Logic (Login)
        // Check if balance covers base fee, if so clear fine.
        const baseFee = await getActivePlanPrice();
        const remainingBaseDues = baseFee - student.balance;

        if (remainingBaseDues <= 0 && (student.paymentStatus !== 'paid' || student.fineAmount > 0)) {
            student.paymentStatus = 'paid';
            student.fineAmount = 0;
            await student.save();
            console.log(`[Login Read-Repair] Student ${student.name} marked as PAID.`);
        }

        const token = jwt.sign({ id: student._id }, JWT_SECRET, { expiresIn: '1h' });
        res.json({
            token,
            student: {
                id: student._id,
                name: student.name,
                email: student.email,
                balance: student.balance,
                profileImage: student.profileImage,
                activePlans: student.activePlans
            }
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Get student by ID
router.get('/:id', async (req, res) => {
    try {
        const student = await Student.findById(req.params.id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        // Auto-correct / Read-Repair Logic
        // If balance is sufficient to cover BASE fees, we assume they paid and clear fines.
        // User Requirement: "fine will be add to the pending amt students only" (implies if base is paid, no fine)
        const baseFee = await getActivePlanPrice();
        const remainingBaseDues = baseFee - student.balance;

        if (remainingBaseDues <= 0 && (student.paymentStatus !== 'paid' || student.fineAmount > 0)) {
            student.paymentStatus = 'paid';
            student.fineAmount = 0;
            await student.save();
            console.log(`[Read-Repair] Student ${student.name} marked as PAID (Base fee covered).`);
        }

        const studentData = student.toObject();
        studentData.monthlyFee = baseFee; // Force dynamic plan price for frontend logic
        res.json(studentData);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Get today's birthdays
router.get('/birthdays/today', async (req, res) => {
    try {
        const today = new Date();
        const month = today.getMonth() + 1; // Months are 0-indexed in JS
        const day = today.getDate();

        // MongoDB aggregation to match month and day of DOB
        const birthdays = await Student.aggregate([
            {
                $project: {
                    name: 1,
                    profileImage: 1,
                    dob: 1,
                    month: { $month: "$dob" },
                    day: { $dayOfMonth: "$dob" }
                }
            },
            {
                $match: {
                    month: month,
                    day: day
                }
            }
        ]);

        res.json(birthdays);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Create student (Signup)
router.post('/', async (req, res) => {
    try {
        let { name, email, password, phone, dob, profileImage, hostelDetails, isEmailVerified, isPhoneVerified } = req.body;

        // Check if student exists (Email OR Phone)
        const existingStudent = await Student.findOne({ $or: [{ email }, { phone }] });
        if (existingStudent) {
            if (existingStudent.email === email) return res.status(400).json({ message: 'Email already exists' });
            if (existingStudent.phone === phone) return res.status(400).json({ message: 'Phone number already exists' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const student = new Student({
            name,
            email,
            phone,
            password: hashedPassword,
            dob,
            profileImage,
            hostelDetails,
            isEmailVerified,
            isPhoneVerified
        });

        const newStudent = await student.save();
        res.status(201).json({
            message: 'Student created successfully',
            studentId: newStudent._id
        });
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Update student profile
router.put('/:id', async (req, res) => {
    try {
        const { name, email, phone, profileImage } = req.body;
        const student = await Student.findById(req.params.id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        if (name) student.name = name;
        if (email) student.email = email;
        if (phone) student.phone = phone;
        if (profileImage) student.profileImage = profileImage;

        const updatedStudent = await student.save();
        res.json({
            message: 'Profile updated successfully',
            student: updatedStudent
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Update FCM Token
router.put('/:id/fcm-token', async (req, res) => {
    try {
        const { fcmToken } = req.body;
        const student = await Student.findById(req.params.id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        student.fcmToken = fcmToken;
        await student.save();

        res.json({ message: 'FCM Token updated' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Change password
router.post('/change-password', async (req, res) => {
    try {
        const { id, currentPassword, newPassword } = req.body;
        const student = await Student.findById(id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        const isMatch = await bcrypt.compare(currentPassword, student.password);
        if (!isMatch) return res.status(400).json({ message: 'Invalid current password' });

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        student.password = hashedPassword;
        await student.save();

        res.json({ message: 'Password updated successfully' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
