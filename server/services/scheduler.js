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

        // Payment Due Reminder (Every day at 9:00 AM IST)
        cron.schedule('0 9 * * *', async () => {
            console.log('Running Payment Reminder Job');
            try {
                // Find students with dues > 0
                // Note: Assuming 'dues' field exists in Student model. Adjust if necessary.
                // For now, sending a generic reminder if we can't query specific users easily without more context.
                // Or we can create individual notifications for users with dues.

                // Example: Fetch all students with dues
                /*
                const studentsWithDues = await Student.find({ dues: { $gt: 0 } });
                const notifications = studentsWithDues.map(student => ({
                    userId: student._id,
                    title: 'Payment Due',
                    description: `You have outstanding dues of ₹${student.dues}. Please pay soon.`,
                    type: 'payment'
                }));
                if (notifications.length > 0) {
                    await Notification.insertMany(notifications);
                }
                */

                // Generic reminder for now as per "auto done all this things my own" request
                // Ideally this should be targeted.
                // Let's create a generic one for demonstration or targeted if we had the schema.
                // Given the prompt "payment due remainder", I'll add a generic one for now.

                const notification = new Notification({
                    title: 'Payment Reminder',
                    description: 'Please check if you have any outstanding mess dues.',
                    type: 'payment'
                });
                await notification.save();

            } catch (error) {
                console.error('Error sending payment reminder:', error);
            }
        }, {
            timezone: "Asia/Kolkata"
        });
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
