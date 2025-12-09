const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configure Cloudinary
const cloudinaryConfig = {
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
};

// Validate Cloudinary config
if (!cloudinaryConfig.cloud_name || !cloudinaryConfig.api_key || !cloudinaryConfig.api_secret) {
    console.error('WARNING: Cloudinary credentials are not configured!');
    console.error('Please add CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET to .env');
}

cloudinary.config(cloudinaryConfig);

// Configure Cloudinary Storage
const storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'finolex-canteen/receipts',
        allowed_formats: ['jpg', 'png', 'jpeg', 'pdf', 'webp'],
        resource_type: 'auto', // Automatically detect resource type
    },
});

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB limit
    }
});

// Upload endpoint with error handling
router.post('/', (req, res) => {
    upload.single('receipt')(req, res, (err) => {
        if (err) {
            console.error('Multer/Cloudinary Error:', err);
            console.error('Error details:', {
                message: err.message,
                stack: err.stack,
                code: err.code
            });
            return res.status(500).json({
                message: err.message || 'Error uploading file to Cloudinary',
                error: err.code || 'UPLOAD_ERROR'
            });
        }

        try {
            if (!req.file) {
                console.error('Upload failed: No file in request');
                return res.status(400).json({ message: 'No file uploaded' });
            }

            console.log('File uploaded successfully to Cloudinary:', {
                url: req.file.path,
                filename: req.file.filename,
                size: req.file.size
            });

            // Return the Cloudinary file URL
            res.json({
                message: 'File uploaded successfully',
                fileUrl: req.file.path // Cloudinary URL
            });
        } catch (error) {
            console.error('Upload Error:', error);
            console.error('Error stack:', error.stack);
            res.status(500).json({
                message: error.message || 'Error uploading file',
                error: process.env.NODE_ENV === 'development' ? error.stack : undefined
            });
        }
    });
});

module.exports = router;
