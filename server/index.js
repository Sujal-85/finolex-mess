require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const functions = require('firebase-functions');

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
// MongoDB Connection
const getMongoUri = () => {
    return process.env.MONGODB_URI ||
        "mongodb+srv://finolex:finolex_canteen@mess.dqhbzlz.mongodb.net/finolex_canteen?appName=Mess";
};

mongoose.connect(getMongoUri(), {
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
    })
    .catch((err) => console.error('MongoDB connection error:', err));

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
const attendanceRoutes = require('./routes/attendance');

const uploadRoutes = require('./routes/upload');
const notificationRoutes = require('./routes/notification');
const scheduler = require('./services/scheduler');

// Initialize Scheduler
scheduler.init();

app.use('/payments', paymentRoutes);
app.use('/menu', menuRoutes);
app.use('/announcements', announcementRoutes);
app.use('/complaints', complaintRoutes);
app.use('/inventory', inventoryRoutes);
app.use('/settings', settingRoutes);
app.use('/students', studentRoutes);
app.use('/users', userRoutes);
app.use('/feedback', feedbackRoutes);
app.use('/attendance', attendanceRoutes);

app.use('/upload', uploadRoutes);
app.use('/notifications', notificationRoutes);
app.use('/verify', require('./routes/verify'));
app.use('/plans', require('./routes/plans'));

// Serve uploaded files statically
app.use('/uploads', express.static('uploads'));

app.get('/ping', (req, res) => {
    res.status(200).send('pong');
});

app.get('/', (req, res) => {
    res.send('Finolex Canteen Server is Running');
});

// Start Server locally if not in Cloud Functions
if (require.main === module) {
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}
// Force Deploy: Scheduler Update
exports.api = functions.https.onRequest(app);
