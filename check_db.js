const mongoose = require('mongoose');
const Transaction = require('./server/models/Transaction');
const Student = require('./server/models/Student');
require('dotenv').config({ path: './server/.env' });

async function checkDB() {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('Connected to DB');

        const transactions = await Transaction.find({}).sort({ date: -1 }).limit(5);
        console.log('--- Latest 5 Transactions ---');
        console.log(JSON.stringify(transactions, null, 2));

        const students = await Student.find({}).limit(1);
        console.log('--- Sample Student ---');
        console.log(JSON.stringify(students, null, 2));

        process.exit(0);
    } catch (e) {
        console.error(e);
        process.exit(1);
    }
}

checkDB();
