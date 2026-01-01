const mongoose = require('mongoose');
const Student = require('./models/Student');
const Plan = require('./models/Plan');

// Connect to MongoDB
mongoose.connect('mongodb+srv://admin:admin123@cluster0.mongodb.net/finolex_canteen?retryWrites=true&w=majority', {
    useNewUrlParser: true,
    useUnifiedTopology: true
});

async function checkData() {
    try {
        const studentCount = await Student.countDocuments();
        console.log(`Total Students: ${studentCount}`);

        const activePlan = await Plan.findOne({ active: true });
        console.log('Active Plan:', activePlan);

        if (activePlan) {
            console.log(`Plan Price: ${activePlan.price}`);
        }

    } catch (err) {
        console.error(err);
    } finally {
        mongoose.disconnect();
    }
}

checkData();
