const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });
const mongoose = require('mongoose');
const Student = require('../models/Student');

const checkStudentPlans = async () => {
    try {
        if (!process.env.MONGODB_URI) throw new Error('MONGODB_URI missing');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('MongoDB Connected');

        // Fetch one student to check their activePlans
        const student = await Student.findOne({});
        if (student) {
            console.log(`\nStudent: ${student.name}`);
            console.log('Active Plans:', JSON.stringify(student.activePlans, null, 2));
            console.log('Balance:', student.balance);
        } else {
            console.log('No students found.');
        }

    } catch (err) {
        console.error(err);
    } finally {
        await mongoose.disconnect();
    }
};

checkStudentPlans();
