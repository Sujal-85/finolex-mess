const cron = require('node-cron');
const Notification = require('../models/Notification');
const Student = require('../models/Student');

const axios = require('axios');

const scheduler = {
    init: () => {
        console.log('Scheduler initialized...');

        // Keep-Alive Ping (Every 10 minutes)
        // Pings the public URL to prevent Render from sleeping
        cron.schedule('*/10 * * * *', async () => {
            console.log('Running Keep-Alive Ping');
            try {
                // Use the public Render URL
                await axios.get('https://finolex-mess.onrender.com/ping');
                console.log('Keep-Alive ping successful');
            } catch (error) {
                console.error('Keep-Alive ping failed:', error.message);
            }
        });

        // Morning Greeting (Every day at 8:00 AM IST)
        cron.schedule('0 8 * * *', async () => {
            console.log('Running Morning Greeting Job');
            try {
                const notification = new Notification({
                    title: 'Good Morning!',
                    description: 'Breakfast is ready. Start your day with a healthy meal!',
                    type: 'mess'
                });
                await notification.save();
                console.log('Morning greeting sent.');
            } catch (error) {
                console.error('Error sending morning greeting:', error);
            }
        }, {
            timezone: "Asia/Kolkata"
        });

        // Lunch Reminder (Every day at 12:30 PM IST)
        cron.schedule('30 12 * * *', async () => {
            console.log('Running Lunch Reminder Job');
            try {
                const notification = new Notification({
                    title: 'Lunch Time!',
                    description: 'Lunch is being served. Check out today\'s menu.',
                    type: 'mess'
                });
                await notification.save();
                console.log('Lunch reminder sent.');
            } catch (error) {
                console.error('Error sending lunch reminder:', error);
            }
        }, {
            timezone: "Asia/Kolkata"
        });

        // Dinner Reminder (Every day at 7:30 PM IST)
        cron.schedule('30 19 * * *', async () => {
            console.log('Running Dinner Reminder Job');
            try {
                const notification = new Notification({
                    title: 'Dinner Time!',
                    description: 'Dinner is ready. Don\'t miss it!',
                    type: 'mess'
                });
                await notification.save();
                console.log('Dinner reminder sent.');
            } catch (error) {
                console.error('Error sending dinner reminder:', error);
            }
        }, {
            timezone: "Asia/Kolkata"
        });

        // 1. Pending Payment Reminder (TESTING: Every 1 Minute)
        // Checks if student is pending/overdue 
        const admin = require('./firebase');

        // ... (existing code)

        // 1. Pending Payment Reminder (Daily at 12:30 PM and 7:30 PM)
        cron.schedule('30 12,19 * * *', async () => {
            console.log('Running Payment Pending Reminder Job');
            try {
                // Fetch Active Plan
                const Plan = require('../models/Plan');
                const plan = await Plan.findOne({ active: true });
                if (!plan || !plan.startDate) {
                    console.log('Skipping payment reminder (No active plan/startDate).');
                    return;
                }

                // Logic: Start reminder from 8th day of startDate
                const now = new Date();
                const eighthDay = new Date(plan.startDate);
                eighthDay.setDate(eighthDay.getDate() + 7); // startDate + 7 = 8th day start

                if (now < eighthDay) {
                    console.log('Skipping payment reminder (Before 8th day of plan).');
                    return;
                }

                const baseFee = plan.price ?? 3500;

                // Find students pending/overdue
                const students = await Student.find({
                    paymentStatus: { $in: ['pending', 'overdue'] }
                });
                console.log(`[DEBUG] Found ${students.length} students with pending status.`);

                const eligibleStudents = [];

                for (const student of students) {
                    const balance = student.balance || 0;
                    let outstanding = 0;

                    if (balance >= baseFee) {
                        outstanding = 0;
                        if (student.paymentStatus !== 'paid') {
                            student.paymentStatus = 'paid';
                            student.fineAmount = 0;
                            await student.save();
                            console.log(`[Scheduler Read-Repair] Marked ${student.name} as paid.`);
                        }
                    } else {
                        const totalFee = baseFee + (student.fineAmount || 0);
                        outstanding = totalFee - balance;
                    }

                    if (outstanding > 0) {
                        eligibleStudents.push({ student, outstanding });
                    }
                }

                if (eligibleStudents.length > 0) {
                    // Create History Notifications
                    const notifications = eligibleStudents.map(({ student, outstanding }) => ({
                        userId: student._id,
                        title: 'Payment Pending ⚠️',
                        description: `Immediate Reminder: Your mess payment of ₹${outstanding} is pending. Please pay to avoid further fines.`,
                        type: 'device_only'
                    }));

                    await Notification.insertMany(notifications);

                    // Send FCM Push
                    const tokens = eligibleStudents
                        .map(({ student }) => student.fcmToken)
                        .filter(token => token && token.length > 0);

                    if (tokens.length > 0) {
                        const message = {
                            notification: {
                                title: 'Payment Pending ⚠️',
                                body: 'Immediate Reminder: Your mess payment is pending.'
                            },
                            tokens: tokens
                        };
                        await admin.messaging().sendEachForMulticast(message);
                    }
                }
            } catch (error) {
                console.error('Error sending payment pending reminder:', error);
            }
        }, { timezone: "Asia/Kolkata" });

        // 2. Daily Fine Calculation (Every Midnight)
        // If not paid by 8th day of plan, add 5 rupees fine daily
        cron.schedule('0 0 * * *', async () => {
            console.log('Running Daily Fine Calculation Job');
            try {
                const Plan = require('../models/Plan');
                const plan = await Plan.findOne({ active: true });
                if (!plan || !plan.startDate) return;

                const now = new Date();
                const eighthDay = new Date(plan.startDate);
                eighthDay.setDate(eighthDay.getDate() + 7);

                if (now < eighthDay) {
                    console.log('Skipping fine calculation (Before 8th day of plan).');
                    return;
                }

                // Find students who are overdue OR pending (and 8th day crossed)
                const targetStudents = await Student.find({
                    paymentStatus: { $in: ['pending', 'overdue'] }
                });

                const fineNotifications = [];

                for (const student of targetStudents) {
                    const planPrice = plan.price ?? 3500;
                    const totalFee = planPrice + (student.fineAmount || 0);
                    const remainingDues = totalFee - student.balance;

                    if (remainingDues <= 0) {
                        student.paymentStatus = 'paid';
                        student.fineAmount = 0;
                        await student.save();
                        continue;
                    }

                    // Calculate Dynamic Fine: ₹5 per day past the 8th day
                    const diffTime = Math.abs(now - eighthDay);
                    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

                    const newFineAmount = diffDays * 5;

                    if (student.fineAmount !== newFineAmount) {
                        student.fineAmount = newFineAmount;
                        student.paymentStatus = 'overdue';
                        await student.save();

                        fineNotifications.push({
                            userId: student._id,
                            title: 'Daily Fine Applied',
                            description: `A fine of ₹5/day has been applied. Total Fine: ₹${student.fineAmount}.`,
                            type: 'urgent'
                        });
                    }
                }

                if (fineNotifications.length > 0) {
                    await Notification.insertMany(fineNotifications);
                }
            } catch (error) {
                console.error('Error applying daily fines:', error);
            }
        }, { timezone: "Asia/Kolkata" });

        // 3. Plan Validity & Renewal check (Daily at Midnight)
        // Renew payment cycle when Plan.endDate is passed
        cron.schedule('0 0 * * *', async () => {
            console.log('Running Plan Validity & Renewal Check Job');
            try {
                const Plan = require('../models/Plan');
                const activePlan = await Plan.findOne({ active: true });

                if (!activePlan || !activePlan.endDate) {
                    console.log('No active plan with end date found for renewal check.');
                    return;
                }

                const now = new Date();
                // Set to midnight today for comparison
                const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                const endDate = new Date(activePlan.endDate);
                // Expiry is at the end of the day of endDate. 
                // We check if "today" has passed the "endDate"
                if (today > endDate) {
                    console.log(`Plan "${activePlan.name}" expired on ${activePlan.endDate}. Triggering Renewal...`);

                    // 1. Reset all students for the new cycle
                    // We set them to pending so they have to pay for the new period
                    // New due date is 10 days from now (or 10th of this month if it's early?)
                    // Let's stick to the concept of "10th of the (newly started) period"
                    const newDueDate = new Date(today.getFullYear(), today.getMonth(), today.getDate() + 10);

                    const resetResult = await Student.updateMany({}, {
                        $set: {
                            paymentStatus: 'pending',
                            paymentDueDate: newDueDate,
                            lastPaymentResetDate: today,
                            fineAmount: 0
                        }
                    });

                    console.log(`Reset payment status for ${resetResult.modifiedCount} students.`);

                    // 2. Update the Plan (Cycle Start/End)
                    // "next day new start will be their"
                    activePlan.startDate = today;
                    // "active until new date is not updated by admin" -> clear end date
                    activePlan.endDate = null;
                    await activePlan.save();

                    // 3. Send Notification
                    const notification = new Notification({
                        title: 'Mess Plan Renewed 📅',
                        description: `The mess plan cycle has been renewed. New period started on ${today.toLocaleDateString()}. Please clear your dues by ${newDueDate.toLocaleDateString()}.`,
                        type: 'mess'
                    });
                    await notification.save();

                    console.log('Date-based renewal complete.');
                } else {
                    console.log(`Plan "${activePlan.name}" is still valid until ${activePlan.endDate}.`);
                }
            } catch (error) {
                console.error('Error in plan renewal job:', error);
            }
        }, { timezone: "Asia/Kolkata" });
        // TEST JOB (Runs every minute)
        // TODO: Remove this after verification
        // cron.schedule('* * * * *', async () => {
        //     console.log('Running Test Notification Job');
        //     try {
        //         const notification = new Notification({
        //             title: 'Test Notification 🔔',
        //             description: `This is a test notification generated at ${new Date().toLocaleTimeString()}`,
        //             type: 'urgent' // Using 'urgent' to ensure it's picked up
        //         });
        //         await notification.save();
        //         console.log('Test notification sent.');
        //     } catch (error) {
        //         console.error('Error sending test notification:', error);
        //     }
        // });
    }
};

module.exports = scheduler;
