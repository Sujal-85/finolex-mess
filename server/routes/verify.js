const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
const axios = require('axios');

// In-memory OTP store (Use Redis/DB in production)
const otpStore = new Map();

// Email Transporter
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // true for 465, false for other ports
    auth: {
        user: 'khedekarsujay720@gmail.com',
        pass: 'hmil kblm wgaq cbqd'
    },
    connectionTimeout: 10000, // 10 seconds
    logger: true,
    debug: true
});

// Verify connection configuration
transporter.verify(function (error, success) {
    if (error) {
        console.log('Transporter Error:', error);
    } else {
        console.log("Server is ready to take our messages");
    }
});

// Fast2SMS Configuration
const FAST2SMS_API_KEY = 'qfW9n2aU8fqaMqgs7c0YBcPLWtqjITgRJ2dwVdBQBoEOLykz3jf9zGAQFDWX';

// Generate 6-digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// Send Email OTP
router.post('/email/send', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ message: 'Email is required' });

        const otp = generateOTP();
        otpStore.set(email, { otp, expires: Date.now() + 10 * 60 * 1000 }); // 10 mins

        await transporter.sendMail({
            from: 'Finolex Canteen <t240671@famt.ac.in>',
            to: email,
            subject: 'Email Verification OTP',
            text: `Your OTP for Finolex Canteen registration is: ${otp}. It expires in 10 minutes.`
        });

        res.json({ success: true, message: 'OTP sent to email' });
    } catch (error) {
        console.error('Email OTP Error:', error);
        res.status(500).json({ success: false, message: error.message || 'Failed to send OTP' });
    }
});

// Verify Email OTP
router.post('/email/verify', (req, res) => {
    const { email, otp } = req.body;
    const storedData = otpStore.get(email);

    if (!storedData) return res.status(400).json({ success: false, message: 'OTP not found or expired' });
    if (Date.now() > storedData.expires) {
        otpStore.delete(email);
        return res.status(400).json({ success: false, message: 'OTP expired' });
    }
    if (storedData.otp !== otp) return res.status(400).json({ success: false, message: 'Invalid OTP' });

    otpStore.delete(email);
    res.json({ success: true, message: 'Email verified successfully' });
});

// Send Mobile OTP
router.post('/mobile/send', async (req, res) => {
    try {
        const { phone } = req.body;
        if (!phone) return res.status(400).json({ message: 'Phone number is required' });

        // Fixed OTP for development/mock mode
        const otp = '123456';
        otpStore.set(phone, { otp, expires: Date.now() + 10 * 60 * 1000 });

        console.log(`[DEV] Mobile OTP for ${phone}: ${otp}`);

        // Mock Mode: Skip API call
        // await axios.get('https://www.fast2sms.com/dev/bulkV2', { ... });

        res.json({ success: true, message: 'OTP sent to mobile (Mock Mode: 123456)' });
    } catch (error) {
        console.error('Mobile OTP Error:', error.response?.data || error.message);
        res.status(500).json({
            success: false,
            message: error.response?.data?.message || error.message || 'Failed to send OTP'
        });
    }
});

// Verify Mobile OTP
router.post('/mobile/verify', (req, res) => {
    const { phone, otp } = req.body;
    const storedData = otpStore.get(phone);

    if (!storedData) return res.status(400).json({ success: false, message: 'OTP not found or expired' });
    if (Date.now() > storedData.expires) {
        otpStore.delete(phone);
        return res.status(400).json({ success: false, message: 'OTP expired' });
    }
    if (storedData.otp !== otp) return res.status(400).json({ success: false, message: 'Invalid OTP' });

    otpStore.delete(phone);
    res.json({ success: true, message: 'Mobile verified successfully' });
});

module.exports = router;
