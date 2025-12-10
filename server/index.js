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

        // Drop legacy indexes if they exist to fix registration error
        try {
            const collection = mongoose.connection.collection('students');
            const indexesToDrop = ['rollNumber_1', 'roll_no_1', 'rollNo_1'];

            indexesToDrop.forEach(indexName => {
                collection.dropIndex(indexName)
                    .then(() => console.log(`Dropped legacy index: ${indexName}`))
                    .catch(err => {
                        // Ignore 'index not found' errors
                        if (err.codeName !== 'IndexNotFound') {
                            console.log(`Legacy index ${indexName} check: ` + (err.codeName || err.message));
                        }
                    });
            });
        } catch (e) {
            console.log('Error checking legacy indexes:', e);
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

        app.use('/api/upload', uploadRoutes);
        app.use('/api/notifications', notificationRoutes);
        app.use('/api/verify', require('./routes/verify'));

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
