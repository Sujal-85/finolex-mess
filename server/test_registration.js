require('dotenv').config();
const mongoose = require('mongoose');
const Student = require('./models/Student');
const bcrypt = require('bcryptjs');

const dummyStudent = {
    name: "Test Dummy",
    email: `dummy_${Date.now()}@example.com`,
    phone: "1234567890",
    password: "Password123!",
    dob: new Date("2000-01-01"),
    year: "3rd Year",
    hostelDetails: {
        isHostelite: true,
        hostelName: "B-Hostel",
        roomNo: "305"
    },
    isEmailVerified: true,
    isPhoneVerified: true
};

async function testRegistration() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        });
        console.log('Connected!');

        console.log('Cleaning up any existing dummy with same email...');
        await Student.deleteOne({ email: dummyStudent.email });

        console.log('Encrypting password...');
        const hashedPassword = await bcrypt.hash(dummyStudent.password, 10);

        console.log('Creating new student with year:', dummyStudent.year);
        const student = new Student({
            ...dummyStudent,
            password: hashedPassword
        });

        const savedStudent = await student.save();
        console.log('Success! Student registered with ID:', savedStudent._id);
        console.log('Saved Year:', savedStudent.year);

        if (savedStudent.year === dummyStudent.year) {
            console.log('Verification Passed: Year field correctly saved.');
        } else {
            console.error('Verification Failed: Year field mismatch.');
        }

        // Cleanup
        // await Student.deleteOne({ _id: savedStudent._id });
        // console.log('Cleanup: Dummy student removed.');

    } catch (error) {
        console.error('Test Failed:', error.message);
    } finally {
        await mongoose.connection.close();
        console.log('Connection closed.');
    }
}

testRegistration();
