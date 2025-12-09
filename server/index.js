require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 4000;

// Middleware
// Middleware
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI || "mongodb+srv://finolex:finolex_canteen@mess.dqhbzlz.mongodb.net/finolex_canteen?appName=Mess", {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
    .then(() => {
        console.log('Connected to MongoDB');

        // Drop legacy index if it exists to fix registration error
        try {
            mongoose.connection.collection('students').dropIndex('rollNumber_1')
                .then(() => console.log('Dropped legacy index: rollNumber_1'))
                .catch(err => console.log('Legacy index rollNumber_1 check: ' + (err.codeName || err.message)));
        } catch (e) {
            console.log('Error checking legacy index:', e);
        }

        // Migration: Add 'days' to all menu items if missing
        try {
            const MenuItem = require('./models/MenuItem');
            MenuItem.updateMany(
                { days: { $exists: false } },
                { $set: { days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] } }
            ).then(result => {
                if (result.modifiedCount > 0) {
                    console.log(`Migrated ${result.modifiedCount} menu items with default days.`);
                }
            }).catch(err => console.error('Menu migration error:', err));
        } catch (error) {
            console.error('Menu migration setup error:', error);
        }

        // Routes
        const paymentRoutes = require('./routes/payments');
        const menuRoutes = require('./routes/menuItems');
        const announcementRoutes = require('./routes/announcements');
        const complaintRoutes = require('./routes/complaints');
        const inventoryRoutes = require('./routes/inventoryItems');
        const settingRoutes = require('./routes/settings');
        const studentRoutes = require('./routes/students');
        const userRoutes = require('./routes/users');
        const feedbackRoutes = require('./routes/feedback');
        const verifyRoutes = require('./routes/verify');
        const uploadRoutes = require('./routes/upload');
        const notificationRoutes = require('./routes/notification');
        const scheduler = require('./services/scheduler');

        // Initialize Scheduler
        scheduler.init();

        app.use('/api/payments', paymentRoutes);
        app.use('/api/menu', menuRoutes);
        app.use('/api/announcements', announcementRoutes);
        app.use('/api/complaints', complaintRoutes);
        app.use('/api/inventory', inventoryRoutes);
        app.use('/api/settings', settingRoutes);
        app.use('/api/students', studentRoutes);
        app.use('/api/users', userRoutes);
        app.use('/api/feedback', feedbackRoutes);
        app.use('/api/verify', verifyRoutes);
        app.use('/api/upload', uploadRoutes);
        app.use('/api/notifications', notificationRoutes);

        // Serve uploaded files statically
        app.use('/uploads', express.static('uploads'));

        app.get('/ping', (req, res) => {
            res.status(200).send('pong');
        });

        app.get('/', (req, res) => {
            res.send('Finolex Canteen Server is Running');
        });

        // Start Server only after DB connection
        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    })
    .catch((err) => console.error('MongoDB connection error:', err));
