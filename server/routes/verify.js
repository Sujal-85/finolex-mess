const express = require('express');
const router = express.Router();
const axios = require('axios'); // Use axios for webhook
const OTP = require('../models/OTP');
require('dotenv').config();

// Send Email OTP via n8n Webhook
router.post('/send-email-otp', async (req, res) => {
    try {
        const { email, name } = req.body;
        if (!email) return res.status(400).json({ message: 'Email is required' });

        // Generate 6 digit OTP
        const otp = Math.floor(100000 + Math.random() * 900000).toString();

        // Save to DB (Delete existing OTPs for this email first)
        await OTP.deleteMany({ email });
        const newOTP = new OTP({ email, otp });
        await newOTP.save();

        console.log(`Generated OTP ${otp} for ${email}`);

        // Professional Email Template
        const emailHtml = `
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body { margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; }
                    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
                    .card { background-color: #ffffff; border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.05); overflow: hidden; }
                    .header { background-color: #2c3e50; padding: 30px; text-align: center; }
                    .header h1 { color: #ffffff; margin: 0; font-size: 24px; font-weight: 600; letter-spacing: 1px; }
                    .content { padding: 40px 30px; text-align: center; }
                    .icon-container { margin-bottom: 30px; }
                    .icon { width: 100px; height: auto; }
                    .title { color: #2c3e50; font-size: 28px; margin-bottom: 10px; font-weight: 700; }
                    .text { color: #7f8c8d; font-size: 16px; line-height: 1.6; margin-bottom: 30px; }
                    .otp-box { background-color: #f8f9fa; border: 2px dashed #3498db; border-radius: 8px; padding: 20px; margin: 0 auto 30px; display: inline-block; }
                    .otp-code { font-size: 36px; font-weight: bold; color: #3498db; letter-spacing: 8px; font-family: 'Courier New', monospace; }
                    .expiry { color: #95a5a6; font-size: 14px; margin-top: 20px; }
                    .expiry-time { color: #e74c3c; font-weight: 600; }
                    .note { border-top: 1px solid #eee; margin-top: 30px; padding-top: 20px; }
                    .note-text { color: #bdc3c7; font-size: 12px; margin: 0; }
                    .footer { background-color: #ecf0f1; padding: 20px; text-align: center; }
                    .footer-text { color: #7f8c8d; font-size: 12px; margin: 0; }
                    
                    /* Mobile Responsive Styles */
                    @media screen and (max-width: 600px) {
                        .container { padding: 10px !important; }
                        .content { padding: 20px 15px !important; }
                        .header { padding: 20px !important; }
                        .otp-box { padding: 15px !important; margin-bottom: 20px !important; width: 100% !important; box-sizing: border-box !important; }
                        .otp-code { font-size: 28px !important; letter-spacing: 4px !important; }
                        .title { font-size: 22px !important; }
                        .text { font-size: 14px !important; }
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <div class="card">
                        <!-- Header -->
                        <div class="header">
                            <h1>FINOLEX CANTEEN</h1>
                        </div>
                        
                        <!-- Content -->
                        <div class="content">
                           
                            <h2 class="title">Verification Code</h2>
                            <p class="text">
                                Hello <strong>${name || 'User'}</strong>,<br><br>
                                Please use the valid verification code below to complete your action at Finolex Canteen.
                            </p>
                            
                            <div class="otp-box">
                                <span class="otp-code">${otp}</span>
                            </div>
                            
                            <p class="expiry">
                                This code will expire in <span class="expiry-time">10 minutes</span>.
                            </p>
                            
                            <div class="note">
                                <p class="note-text">
                                    If you didn't request this email, you can safely ignore it.
                                </p>
                            </div>
                        </div>
                        
                        <!-- Footer -->
                        <div class="footer">
                            <p class="footer-text">
                                &copy; ${new Date().getFullYear()} Finolex Academy of Management and Technology
                            </p>
                        </div>
                    </div>
                </div>
            </body>
            </html>
        `;

        const functions = require('firebase-functions');
        // Send to n8n Webhook
        const webhookUrl = process.env.N8N_EMAIL_WEBHOOK_URL;

        if (!webhookUrl) {
            console.warn('N8N_EMAIL_WEBHOOK_URL is not set!');
            // Fallback for dev - just return success
            return res.json({
                success: true,
                message: 'OTP generated (Webhook URL missing - Check logs)',
                devOtp: process.env.NODE_ENV !== 'production' ? otp : undefined
            });
        }

        try {
            const webhookResponse = await axios.post(webhookUrl, {
                email: email,
                name: name || 'User',
                subject: 'Finolex Canteen - Email Verification',
                html: emailHtml,
                otp: otp // Sending raw OTP just in case n8n wants to use it for other logic
            });

            console.log('OTP sent via n8n webhook. Status:', webhookResponse.status);
            // Return success (and OTP for dev testing)
            res.json({
                success: true,
                message: 'OTP sent successfully',
                devOtp: process.env.NODE_ENV !== 'production' ? otp : undefined
            });

        } catch (webhookError) {
            console.error('n8n Webhook Error:', webhookError.message);
            if (webhookError.response) {
                console.error('n8n Response Data:', webhookError.response.data);
            }

            // Don't block user if email fails, but log it
            res.json({
                success: true,
                message: 'OTP generated (Email service experiencing delays)',
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
            await OTP.deleteMany({ email }); // Clean up
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
