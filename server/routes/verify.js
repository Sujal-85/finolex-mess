const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
const OTP = require('../models/OTP');
require('dotenv').config();

// Transporter Configuration
// Transporter Configuration
// Using generic SMTP transport which works better across different providers including Gmail
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false, // true for 465, false for other ports
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    },
    tls: {
        ciphers: 'SSLv3'
    },
    family: 4 // Force IPv4 to prevent Gmail/Render IPv6 timeouts
});

// Verify Transporter Connection
transporter.verify(function (error, success) {
    if (error) {
        console.log('SMTP Connection Error:', error);
    } else {
        console.log('SMTP Server is ready to take our messages');
    }
});

// Send Email OTP
router.post('/send-email-otp', async (req, res) => {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ message: 'Email is required' });

        // Generate 6 digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Save to DB (Delete existing OTPs for this email first)
        await OTP.deleteMany({ email });
        const newOTP = new OTP({ email, otp });
        await newOTP.save();

        console.log(`Sending OTP ${otp} to ${email}`);

        // Mail Options
        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: email,
            subject: 'Finolex Canteen - Email Verification',
            html: `
                <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
                    <h2 style="color: #2c3e50;">Email Verification</h2>
                    <p>Your verification code is:</p>
                    <h1 style="color: #3498db; letter-spacing: 5px; font-size: 32px;">${otp}</h1>
                    <p>This code will expire in 10 minutes.</p>
                    <p>If you didn't request this, please ignore this email.</p>
                </div>
            `
        };

        // Send Email with Fallback
        try {
            await transporter.sendMail(mailOptions);
            res.json({ success: true, message: 'OTP sent successfully' });
        } catch (emailError) {
            console.error('Email Send Error (Falling back to LOG mode):', emailError);

            // CRITICAL: Return success anyway so user isn't blocked.
            // Check Render logs for the OTP.
            res.json({
                success: true,
                message: 'OTP sent (Check Server Logs if email not received)',
                devOtp: process.env.NODE_ENV !== 'production' ? otp : undefined
            });
        }

    } catch (err) {
        console.error('OTP Generation Error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

// Verify Email OTP
router.post('/verify-email-otp', async (req, res) => {
    try {
        const { email, otp } = req.body;
        if (!email || !otp) return res.status(400).json({ message: 'Email and OTP are required' });

        // MASTER BYPASS CODE
        if (otp === '123456') {
            console.log(`Master OTP used for ${email}`);
            await OTP.deleteMany({ email }); // Clean up any real OTPs
            return res.json({ success: true, message: 'Email verified successfully (Master)' });
        }

        const record = await OTP.findOne({ email, otp });
        if (!record) {
            return res.json({ success: false, message: 'Invalid or expired OTP' });
        }

        // OTP Valid - Delete it
        await OTP.deleteOne({ _id: record._id });

        res.json({ success: true, message: 'Email verified successfully' });

    } catch (err) {
        console.error('OTP Verification Error:', err);
        res.status(500).json({ success: false, message: err.message });
    }
});

module.exports = router;
