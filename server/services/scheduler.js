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
                // Check if date is 8th or later
                const today = new Date();
                if (today.getDate() < 8) {
                    console.log('Skipping payment reminder (Before 8th).');
                    return;
                }

                // Fetch Active Plan Price
                const plan = await require('../models/Plan').findOne({ active: true });
                const baseFee = plan ? (plan.price ?? plan.amount) : 3500;

                // Find students pending/overdue
                const students = await Student.find({
                    paymentStatus: { $in: ['pending', 'overdue'] }
                });
                console.log(`[DEBUG] Found ${students.length} students with pending status.`);

                const eligibleStudents = [];

                for (const student of students) {
                    // Check logic: If base fee is covered, ignore fine for reminder purposes
                    // Or follow standard "Read-Repair" logic
                    const balance = student.balance || 0;

                    // Simple Outstanding Check
                    let outstanding = 0;

                    // If balance covers base fee, treat as paid for reminder purposes (User requirement)
                    if (balance >= baseFee) {
                        outstanding = 0;
                        // Optionally auto-repair status here
                        if (student.paymentStatus !== 'paid') {
                            student.paymentStatus = 'paid';
                            student.fineAmount = 0;
                            await student.save();
                            console.log(`[Scheduler Read-Repair] Marked ${student.name} as paid.`);
                        }
                    } else {
                        // Not covered base fee
                        const totalFee = baseFee + (student.fineAmount || 0);
                        outstanding = totalFee - balance;
                    }

                    if (outstanding > 0) {
                        eligibleStudents.push({ student, outstanding });
                    }
                }

                console.log(`[DEBUG] ${eligibleStudents.length} students actually have outstanding dues > 0.`);

                if (eligibleStudents.length > 0) {
                    // 1. Create Database Notifications (History)
                    const notifications = eligibleStudents.map(({ student, outstanding }) => ({
                        userId: student._id,
                        title: 'Payment Pending ⚠️',
                        description: `Immediate Reminder: Your mess payment of ₹${outstanding} is pending. Please pay to avoid further fines.`,
                        type: 'device_only'
                    }));

                    await Notification.insertMany(notifications);
                    console.log('Payment pending reminders inserted (Device Only).');

                    // 2. Send FCM Push Notifications
                    const tokens = eligibleStudents
                        .map(({ student }) => student.fcmToken)
                        .filter(token => token && token.length > 0);

                    console.log(`[DEBUG] Found ${tokens.length} valid FCM tokens.`);

                    if (tokens.length > 0) {
                        const message = {
                            notification: {
                                title: 'Payment Pending ⚠️',
                                body: 'Immediate Reminder: Your mess payment is pending.'
                            },
                            tokens: tokens
                        };

                        try {
                            const response = await admin.messaging().sendEachForMulticast(message);
                            console.log(response.successCount + ' messages were sent successfully');
                        } catch (error) {
                            console.log('Error sending FCM message:', error);
                        }
                    }
                }
            } catch (error) {
                console.error('Error sending payment pending reminder:', error);
            }
        }, { timezone: "Asia/Kolkata" });



        // 2. Daily Fine Calculation (Every Midnight)
        // If not paid by due date, add 5 rupees fine daily override
        cron.schedule('0 0 * * *', async () => {
            console.log('Running Daily Fine Calculation Job');
            try {
                const now = new Date();

                // Find students who are overdue OR pending who have crossed the date
                const overdueStudents = await Student.find({
                    paymentStatus: { $in: ['pending', 'overdue'] },
                    paymentDueDate: { $lt: now }
                });

                const fineNotifications = [];

                for (const student of overdueStudents) {
                    // Check if they have actually paid (Balance >= Total Fee)
                    const totalFee = (student.monthlyFee || 3500) + (student.fineAmount || 0);
                    const remainingDues = totalFee - student.balance;

                    if (remainingDues <= 0) {
                        // Student has enough balance, mark as paid and skip fine
                        student.paymentStatus = 'paid';
                        await student.save();
                        console.log(`Student ${student.name} marked as PAID (Balance sufficient). Skipping fine.`);
                        continue;
                    }

                    // Update Status
                    student.paymentStatus = 'overdue';

                    // Add Fine (5 Rs Daily)
                    student.fineAmount = (student.fineAmount || 0) + 5;
                    await student.save();

                    // Prepare Notification
                    fineNotifications.push({
                        userId: student._id,
                        title: 'Daily Fine Applied',
                        description: `A fine of ₹5 has been applied. Total Fine: ₹${student.fineAmount}. Due: ₹${Math.max(0, remainingDues + 5)}`, // remainingDues was before this 5rs, so +5
                        type: 'urgent'
                    });
                }

                if (fineNotifications.length > 0) {
                    await Notification.insertMany(fineNotifications);
                    console.log(`Applied fines and sent notifications to ${fineNotifications.length} students.`);
                }

            } catch (error) {
                console.error('Error applying daily fines:', error);
            }
        }, { timezone: "Asia/Kolkata" });

        // 3. Monthly Renewal (1st of Every Month)
        // Renew payment submission logic
        cron.schedule('0 0 1 * *', async () => {
            console.log('Running Monthly Payment Renewal Job');
            try {
                const now = new Date();
                const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 10); // Due date 10th of next month? Or current?
                // User said "Renew... from day of every month".
                // Let's set Due Date to 10th of THIS new month.
                const newDueDate = new Date(now.getFullYear(), now.getMonth(), 10);

                // Update ALL students
                // Note: We might want to keep 'overdue' status if they haven't paid previous? 
                // Or just reset for the new cycle (Dues accumulate in balance/fine, but 'status' resets for the new bill)?
                // User said "Renew the next month payment submission".
                // I will Reset status to 'pending' (so they aren't 'overdue' for the NEW bill immediately)
                // But their Balance should reflect previous dues (handled in Student Balance ideally).

                await Student.updateMany({}, {
                    $set: {
                        paymentStatus: 'pending',
                        paymentDueDate: newDueDate,
                        // We don't reset fineAmount here likely, as they still owe it? 
                        // Or maybe fine resets per month? Usually fines stick.
                        // Keeping fineAmount.
                        lastPaymentResetDate: now
                    }
                });

                const notification = new Notification({
                    title: 'New Month Started',
                    description: 'Mess fees for this month are now generated. Please pay by the 10th.',
                    type: 'mess'
                });
                await notification.save();

                console.log('Monthly renewal complete.');

            } catch (error) {
                console.error('Error in monthly renewal:', error);
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
