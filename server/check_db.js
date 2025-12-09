const mongoose = require('mongoose');
const Transaction = require('./models/Transaction');
const Student = require('./models/Student');
require('dotenv').config();

mongoose.connect(process.env.MONGODB_URI || "mongodb+srv://finolex:finolex_canteen@mess.dqhbzlz.mongodb.net/finolex_canteen?appName=Mess", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
    .then(async () => {
        console.log('Connected to DB');

        // Check for the 3000 amount specifically or just list last few
        const transactions = await Transaction.find({ amount: 3000 });
        console.log('\n--- TRANSACTIONS WITH AMOUNT 3000 ---');
        if (transactions.length === 0) console.log("No transaction found with amount 3000");
        transactions.forEach(t => {
            console.log(`ID: ${t._id} | Student: ${t.studentId} | Amt: ${t.amount} | Status: ${t.status} | Date: ${t.date}`);
        });

        const allTransactions = await Transaction.find({}).sort({ date: -1 }).limit(5);
        console.log('\n--- LAST 5 TRANSACTIONS (ALL) ---');
        allTransactions.forEach(t => {
            console.log(`ID: ${t._id} | Student: ${t.studentId} | Amt: ${t.amount} | Status: ${t.status}`);
        });

        const students = await Student.find({}, 'name balance');
        console.log('\n--- STUDENT BALANCES ---');
        students.forEach(s => console.log(`${s.name}: ${s.balance}`));

        mongoose.disconnect();
    })
    .catch(err => {
        console.error(err);
    });
