const cron = require('node-cron');
const Notification = require('../models/Notification');
const Student = require('../models/Student');
const admin = require('./firebase'); // Import Firebase Admin
const axios = require('axios');

const scheduler = {
    init: () => {
        console.log('Scheduler initialized...');

        // Helper: Send Global FCM
        const sendGlobalFCM = async (title, body) => {
            try {
                // Fetch students with tokens
                // Fetch students with tokens
                const students = await Student.find({
                    fcmToken: { $exists: true, $ne: null },
                    'settings.messAlerts': { $ne: false } // Only send if NOT explicitly disabled
                }).select('fcmToken');

                const tokens = students
                    .map(s => s.fcmToken)
                    .filter(t => t && t.length > 0);

                if (tokens.length > 0) {
                    console.log(`Sending Global FCM to ${tokens.length} devices...`);
                    // Firebase multicast (batches of 500 automatically handled by sendEachForMulticast usually, 
                    // but for safety with large numbers, we strictly rely on sendEachForMulticast's array handling)
                    // sendEachForMulticast accepts up to 500 tokens per call.

                    const batchSize = 500;
                    for (let i = 0; i < tokens.length; i += batchSize) {
                        const batchTokens = tokens.slice(i, i + batchSize);
                        if (batchTokens.length > 0) {
                            await admin.messaging().sendEachForMulticast({
                                notification: { title, body },
                                android: {
                                    priority: 'high',
                                    notification: {
                                        color: '#3498db',
                                        sound: 'default',
                                        priority: 'high',
                                        icon: 'ic_launcher',
                                        channelId: 'high_importance_channel'
                                    }
                                },
                                apns: {
                                    payload: {
                                        aps: {
                                            sound: 'default'
                                        }
                                    }
                                },
                                tokens: batchTokens
                            });
                        }
                    }
                    console.log('Global FCM sent successfully.');
                } else {
                    console.log('No FCM tokens found for global broadcast.');
                }
            } catch (error) {
                console.error('Error sending Global FCM:', error);
            }
        };

        // Keep-Alive Ping (Every 10 minutes)
        // Pings the public URL to prevent Render from sleeping
        cron.schedule('*/10 * * * *', async () => {
            console.log('Running Keep-Alive Ping');
            try {
                // Use the public Cloud Functions URL
                await axios.get('https://api-457xe7azkq-uc.a.run.app/ping');
                console.log('Keep-Alive ping successful');
            } catch (error) {
                console.error('Keep-Alive ping failed:', error.message);
            }
        });

        // Morning Greeting (Every day at 8:00 AM IST)
        cron.schedule('0 8 * * *', async () => {
            console.log('Running Morning Greeting Job');
            try {
                const title = 'Good Morning!';
                const description = 'Breakfast is ready. Start your day with a healthy meal!';

                const notification = new Notification({
                    title: title,
                    description: description,
                    type: 'mess'
                });
                await notification.save();

                // Send FCM
                await sendGlobalFCM(title, description);

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
                const title = 'Lunch Time!';
                const description = 'Lunch is being served. Check out today\'s menu.';

                const notification = new Notification({
                    title: title,
                    description: description,
                    type: 'mess'
                });
                await notification.save();

                // Send FCM
                await sendGlobalFCM(title, description);

                console.log('Lunch reminder sent.');
            } catch (error) {
                console.error('Error sending lunch reminder:', error);
            }
        }, {
            timezone: "Asia/Kolkata"
        });

        // Dinner Reminder (Every day at 7:30 PM IST)
        // Dinner Reminder (Every day at 7:30 PM IST)
        cron.schedule('30 19 * * *', async () => {
            console.log('Running Dinner Reminder Job');
            try {
                const title = 'Dinner Time!';
                const description = 'Dinner is ready. Have a pleasant evening!';

                const notification = new Notification({
                    title: title,
                    description: description,
                    type: 'mess'
                });
                await notification.save();

                // Send FCM
                await sendGlobalFCM(title, description);

                console.log('Dinner reminder sent.');
            } catch (error) {
                console.error('Error sending dinner reminder:', error);
            }
        }, {
            timezone: "Asia/Kolkata"
        });

        // 4. GLOBAL PLAN SYNC (DISABLED to prevent conflicts with Mobile App Scheduler)
        // We rely on the Mobile App (DashboardBloc) or triggered events to sync plans.
        // The previous logic was aggressively reverting balances.
        /*
        cron.schedule('*\/30 * * * * *', async () => {
             // ... Code removed/commented out to prevent Balance Reversion ...
        });
        */

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

                            // CLEANUP: Remove stale notifications
                            try {
                                await Notification.deleteMany({
                                    userId: student._id,
                                    title: { $in: ['Payment Pending ⚠️', 'Daily Fine Applied'] }
                                });
                            } catch (e) {
                                console.error('Error cleaning up notifications in scheduler:', e);
                            }
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
        // If balance > 0 after 10 days of plan start, add 5 rupees fine daily to balance
        cron.schedule('0 0 * * *', async () => {
            console.log('Running Daily Fine Calculation Job');
            try {
                const Plan = require('../models/Plan');
                // We should probably check each student's specific active plans if they have different start dates,
                // but for now, assuming a global plan start date structure as per existing code, or checking student's active plans.
                // The existing code relied on a global active plan. 
                // However, students might have specific activePlans. 
                // Let's stick to the existing pattern of fetching the global active plan for reference, 
                // but strictly speaking, we should check the student's specific plan start date if available.

                const plan = await Plan.findOne({ active: true });
                // If no global plan, we might surely skip? Or should we check student specific plans?
                // The user request implies: "10 days due date form the starting date of the plan".
                // Let's proceed with finding students who have active plans.

                // Find students with balance > 0
                const targetStudents = await Student.find({
                    balance: { $gt: 0 }
                });

                const fineNotifications = [];

                for (const student of targetStudents) {
                    // Check student's active plans to find the relevant start date
                    // If multiple plans, logic might be complex. User said "queue at the top".
                    // For fine calculation, if ANY plan is overdue (10 days passed) and balance > 0, we charge fine?
                    // User says: "If balance is > 0 after the (10 days due date form the starting date of the plan) 10 days fine will be start"
                    // So we need to find the earliest active plan? Or just THE plan.

                    // Fallback to global plan start date if student has no specific active plans with dates
                    let planStartDate = plan?.startDate;

                    // BETTER LOGIC: Use the student's activePlans array.
                    if (student.activePlans && student.activePlans.length > 0) {
                        // Find the earliest 'pending' plan? or just the active one?
                        // "starting date of the plan"
                        // usage of global plan.startDate in previous code suggests a synchronous start for everyone?
                        // Let's use the student's first active plan start date if available.
                        const activePlan = student.activePlans.find(p => p.status === 'pending' || p.status === 'paid'); // usually pending ones matter
                        if (activePlan && activePlan.startDate) {
                            planStartDate = activePlan.startDate;
                        }
                    }

                    if (!planStartDate) continue;

                    const now = new Date();
                    const tenDaysAfterStart = new Date(planStartDate);
                    tenDaysAfterStart.setDate(tenDaysAfterStart.getDate() + 10);

                    // Normalize dates to midnight for comparison to avoid time issues
                    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                    const thresholdDate = new Date(tenDaysAfterStart.getFullYear(), tenDaysAfterStart.getMonth(), tenDaysAfterStart.getDate());

                    if (today > thresholdDate) {
                        // "this checking is for every day and charge fine 5 until not pay money"
                        // "remove that [fine field] and starting adding fine in the balance only"

                        student.balance += 5;
                        await student.save();

                        fineNotifications.push({
                            userId: student._id,
                            title: 'Daily Fine Applied',
                            description: `A fine of ₹5 has been added to your balance due to overdue payment.`,
                            type: 'urgent'
                        });
                        console.log(`Applied fine to student ${student.name} (${student._id}). New Balance: ${student.balance}`);
                    }
                }

                if (fineNotifications.length > 0) {
                    await Notification.insertMany(fineNotifications);

                    // SEND FCM for Fines
                    // We need to fetch tokens for the users in fineNotifications
                    const userIds = fineNotifications.map(n => n.userId);
                    const finedStudentsWithTokens = await Student.find({
                        _id: { $in: userIds },
                        fcmToken: { $exists: true, $ne: null }
                    }).select('fcmToken');

                    const tokens = finedStudentsWithTokens.map(s => s.fcmToken);

                    if (tokens.length > 0) {
                        const batchSize = 500;
                        for (let i = 0; i < tokens.length; i += batchSize) {
                            const batchTokens = tokens.slice(i, i + batchSize);
                            if (batchTokens.length > 0) {
                                await admin.messaging().sendEachForMulticast({
                                    notification: {
                                        title: 'Daily Fine Applied',
                                        body: 'A fine of ₹5 has been added to your balance due to overdue payment.'
                                    },
                                    android: {
                                        priority: 'high',
                                        notification: {
                                            channelId: 'high_importance_channel'
                                        }
                                    },
                                    tokens: batchTokens
                                });
                            }
                        }
                        console.log(`Sent Fine FCM to ${tokens.length} devices.`);
                    }
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
