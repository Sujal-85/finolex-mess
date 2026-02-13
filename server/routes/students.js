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
        // 1. LAZY SYNC: Fetch all plans to ensure student profile is up-to-date
        // This handles cases where Plans are created/deleted on the Admin Backend (Render)
        // but this Student Backend (Firebase) didn't receive the trigger.
        const allPlans = await Plan.find({});
        const activeDbPlans = allPlans.filter(p => p.active === true || String(p.active) === 'true');
        const allPlanIds = new Set(allPlans.map(p => p._id.toString()));

        let modified = false;

        // A. Add Missing Active Plans
        for (const dbPlan of activeDbPlans) {
            const alreadyHas = student.activePlans.some(p => p.planId.toString() === dbPlan._id.toString());
            if (!alreadyHas) {
                console.log(`[Lazy Sync] Adding missing plan ${dbPlan.name} to ${student.name}`);
                student.activePlans.push({
                    planId: dbPlan._id,
                    name: dbPlan.name,
                    price: dbPlan.price ?? dbPlan.amount ?? 0,
                    startDate: dbPlan.startDate,
                    endDate: dbPlan.endDate,
                    status: 'pending',
                    addedAt: new Date()
                });
                // Update Balance (Add, don't replace)
                const planPrice = dbPlan.price ?? dbPlan.amount ?? 0;
                student.balance = (student.balance || 0) + planPrice;
                student.paymentStatus = student.balance > 0 ? "pending" : "paid";

                modified = true;
            }
        }

        // B. Remove Deleted Plans (Zombie Cleanups)
        const initialCount = student.activePlans.length;
        student.activePlans = student.activePlans.filter(p => allPlanIds.has(p.planId.toString()));
        if (student.activePlans.length !== initialCount) {
            console.log(`[Lazy Sync] Removed ${initialCount - student.activePlans.length} deleted plans from ${student.name}`);
            modified = true;
        }

        // C. Recalculation REMOVED to prevent balance reversion.

        if (modified) {
            await student.save();
            console.log(`[Lazy Sync] Updated profile for ${student.name}. New Balance: ${student.balance}`);
        }

        const token = jwt.sign({ id: student._id }, JWT_SECRET, { expiresIn: '30d' });
        res.json({
            token,
            student: {
                id: student._id,
                name: student.name,
                email: student.email,
                balance: student.balance,
                profileImage: student.profileImage,
                balance: student.balance,
                profileImage: student.profileImage,
                year: student.year,
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
        // 1. LAZY SYNC: Fetch all plans to ensure student profile is up-to-date
        const allPlans = await Plan.find({});
        const activeDbPlans = allPlans.filter(p => p.active === true || String(p.active) === 'true');
        const allPlanIds = new Set(allPlans.map(p => p._id.toString()));

        let modified = false;

        // A. Add Missing Active Plans
        for (const dbPlan of activeDbPlans) {
            const alreadyHas = student.activePlans.some(p => p.planId.toString() === dbPlan._id.toString());
            if (!alreadyHas) {
                console.log(`[Lazy Sync] Adding missing plan ${dbPlan.name} to ${student.name}`);
                student.activePlans.push({
                    planId: dbPlan._id,
                    name: dbPlan.name,
                    price: dbPlan.price ?? dbPlan.amount ?? 0,
                    startDate: dbPlan.startDate,
                    endDate: dbPlan.endDate,
                    status: 'pending',
                    addedAt: new Date()
                });

                // Update Balance (Add, don't replace)
                const planPrice = dbPlan.price ?? dbPlan.amount ?? 0;
                student.balance = (student.balance || 0) + planPrice;
                student.paymentStatus = student.balance > 0 ? "pending" : "paid";

                modified = true;
            }
        }

        // B. Remove Deleted Plans
        const initialCount = student.activePlans.length;
        student.activePlans = student.activePlans.filter(p => allPlanIds.has(p.planId.toString()));
        if (student.activePlans.length !== initialCount) {
            console.log(`[Lazy Sync] Removed ${initialCount - student.activePlans.length} deleted plans from ${student.name}`);
            modified = true;
        }

        // C. Recalculation REMOVED to prevent balance reversion.

        if (modified) {
            await student.save();
        }

        const studentData = student.toObject();
        // studentData.monthlyFee = baseFee; // REMOVED: baseFee is undefined
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
        let { name, email, password, phone, dob, profileImage, hostelDetails, year, isEmailVerified, isPhoneVerified } = req.body;

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
            year,
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
        const { name, email, phone, profileImage, settings } = req.body;
        const student = await Student.findById(req.params.id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        if (name) student.name = name;
        if (email) student.email = email;
        if (phone) student.phone = phone;
        if (phone) student.phone = phone;
        if (profileImage) student.profileImage = profileImage;
        if (req.body.year) student.year = req.body.year;
        if (settings) {
            // merge existing with new
            student.settings = { ...student.settings, ...settings };
        }

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

// Delete account
router.delete('/:id', async (req, res) => {
    try {
        const student = await Student.findByIdAndDelete(req.params.id);
        if (!student) return res.status(404).json({ message: 'Student not found' });

        // Ideally, we should also delete related data (Notifications, Payments, etc.)
        // For now, we are deleting the primary user record as requested.

        res.json({ message: 'Account deleted successfully' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

module.exports = router;
