const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
const OTP = require('../models/OTP');
require('dotenv').config();

// Transporter Configuration
// Using generic SMTP transport which works better across different providers including Gmail
const transporter = nodemailer.createTransport({
    service: 'gmail', // Built-in service for Gmail
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
    }
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

        // Send Email
        try {
            await transporter.sendMail(mailOptions);
            res.json({ success: true, message: 'OTP sent successfully' });
        } catch (emailError) {
            console.error('Email Send Error:', emailError);

            // Fallback for Development/Testing if credentials fail
            if (process.env.NODE_ENV !== 'production') {
                console.log('DEV MODE: Returning success despite email error. OTP was:', otp);
                return res.json({
                    success: true,
                    message: 'DEV: OTP logged to console (Email failed)',
                    devOtp: otp
                });
            }

            res.status(500).json({
                success: false,
                message: 'Failed to send email. Check server logs.',
                error: emailError.message
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

        const record = await OTP.findOne({ email, otp });
        if (!record) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
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
