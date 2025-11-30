const express = require('express');
const router = express.Router();
const Student = require('../models/Student');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Secret key (should be in .env)
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

// Login
router.post('/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const student = await Student.findOne({ email });
        if (!student) return res.status(404).json({ message: 'Student not found' });

        const isMatch = await bcrypt.compare(password, student.password);
        if (!isMatch) return res.status(400).json({ message: 'Invalid credentials' });

        const token = jwt.sign({ id: student._id, rollNo: student.rollNo }, JWT_SECRET, { expiresIn: '1h' });
        res.json({
            token,
            student: {
                id: student._id,
                name: student.name,
                rollNo: student.rollNo,
                email: student.email,
                balance: student.balance,
                profileImage: student.profileImage
            }
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Get student by rollNo
router.get('/:rollNo', async (req, res) => {
    try {
        const student = await Student.findOne({ rollNo: req.params.rollNo });
        if (!student) return res.status(404).json({ message: 'Student not found' });
        res.json(student);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Create student (Signup)
router.post('/', async (req, res) => {
    try {
        let { name, rollNo, email, password, phone, profileImage } = req.body;

        // Auto-generate rollNo if not provided
        if (!rollNo) {
            const randomNum = Math.floor(100000 + Math.random() * 900000); // 6 digit random number
            rollNo = `STU${randomNum}`;
        }

        // Check if student exists
        const existingStudent = await Student.findOne({ $or: [{ rollNo }, { email }] });
        if (existingStudent) return res.status(400).json({ message: 'Student already exists' });

        const hashedPassword = await bcrypt.hash(password, 10);

        const student = new Student({
            name,
            rollNo,
            email,
            phone,
            password: hashedPassword,
            profileImage
        });

        const newStudent = await student.save();
        res.status(201).json({
            message: 'Student created successfully',
            studentId: newStudent.rollNo
        });
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

module.exports = router;
