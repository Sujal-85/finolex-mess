const router = require('express').Router();
const Attendance = require('../models/Attendance');
const Student = require('../models/Student');
const verifyToken = require('../middleware/auth');

const getStartOfDay = (date = new Date()) => {
    // Indian Standard Time is UTC + 5:30
    const istOffset = 5.5 * 60 * 60 * 1000;

    // 1. Get current UTC timestamp
    const utcTime = new Date(date).getTime();

    // 2. Shift time to pretend it's UTC (so we can use UTC methods to floor)
    // Effectively obtaining "IST Clock Time" in UTC variable
    const istTime = new Date(utcTime + istOffset);

    // 3. Floor to start of day (00:00:00.000)
    istTime.setUTCHours(0, 0, 0, 0);

    // 4. Shift back to real UTC
    // This gives the UTC timestamp corresponding to 00:00 IST
    return new Date(istTime.getTime() - istOffset);
};

// @route   POST /api/attendance/mark
// @desc    Mark attendance for a specific meal today
// @access  Private (Student)
router.post('/mark', verifyToken, async (req, res) => {
    try {
        const studentId = req.user.id || req.user._id;
        const { mealType } = req.body; // 'breakfast', 'lunch', 'dinner'

        if (!['breakfast', 'lunch', 'dinner'].includes(mealType)) {
            return res.status(400).json({ message: 'Invalid meal type' });
        }

        const today = getStartOfDay();

        // Check or Create
        let attendance = await Attendance.findOne({
            student: studentId,
            date: today
        });

        if (!attendance) {
            attendance = new Attendance({
                student: studentId,
                date: today
            });
        }

        // Check if already pending or processed (prevent spamming, but allow if 'not_marked')
        const currentStatus = attendance.meals[mealType].status;
        if (currentStatus !== 'not_marked') {
            return res.status(400).json({
                message: `Attendance for ${mealType} is already ${currentStatus}`,
                status: currentStatus
            });
        }

        // Update Status
        attendance.meals[mealType].status = 'pending';
        attendance.meals[mealType].markedAt = new Date();
        attendance.updatedAt = new Date();

        await attendance.save();

        // [NEW] Update Daily Aggregated Stats
        const DailyTracking = require('../models/DailyTracking');
        await DailyTracking.findOneAndUpdate(
            { date: today },
            {
                $inc: { [`stats.${mealType}`]: 1 },
                $setOnInsert: { date: today }
            },
            { upsert: true, new: true }
        );

        res.status(201).json({
            message: `${mealType.charAt(0).toUpperCase() + mealType.slice(1)} attendance marked. Waiting for verification.`,
            attendance
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/attendance/status
// @desc    Get today's attendance status
// @access  Private (Student)
router.get('/status', verifyToken, async (req, res) => {
    try {
        const studentId = req.user.id || req.user._id;
        const today = getStartOfDay();

        const attendance = await Attendance.findOne({
            student: studentId,
            date: today
        });

        if (!attendance) {
            return res.json({
                status: 'not_marked',
                meals: {
                    breakfast: { status: 'not_marked' },
                    lunch: { status: 'not_marked' },
                    dinner: { status: 'not_marked' }
                }
            });
        }

        res.json({ attendance });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
});

// @route   GET /api/attendance/history
// @desc    Get attendance history
// @access  Private (Student)
router.get('/history', verifyToken, async (req, res) => {
    try {
        const studentId = req.user.id || req.user._id;

        // Sorting by date descending
        const history = await Attendance.find({ student: studentId })
            .sort({ date: -1 })
            .limit(30);

        res.json(history);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Server Error' });
    }
});

module.exports = router;
