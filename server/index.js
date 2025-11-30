require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection
// MongoDB Connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/finolex-canteen', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
})
    .then(() => {
        console.log('Connected to MongoDB');

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

        app.use('/api/payments', paymentRoutes);
        app.use('/api/menu', menuRoutes);
        app.use('/api/announcements', announcementRoutes);
        app.use('/api/complaints', complaintRoutes);
        app.use('/api/inventory', inventoryRoutes);
        app.use('/api/settings', settingRoutes);
        app.use('/api/students', studentRoutes);
        app.use('/api/users', userRoutes);
        app.use('/api/feedback', feedbackRoutes);

        app.get('/', (req, res) => {
            res.send('Finolex Canteen Server is Running');
        });

        // Start Server only after DB connection
        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    })
    .catch((err) => console.error('MongoDB connection error:', err));
