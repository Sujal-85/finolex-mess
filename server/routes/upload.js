const express = require('express');
const router = express.Router();
const Busboy = require('busboy'); // Use busboy directly
const cloudinary = require('cloudinary').v2;
const os = require('os');
const path = require('path');
const fs = require('fs');

// Configure Cloudinary
const cloudinaryConfig = {
    cloud_name: 'duwxtqbkh',
    api_key: '898752717285898',
    api_secret: 'zgrRSDYRRTIy7abr9swr5BoJ61c'
};
cloudinary.config(cloudinaryConfig);

router.post('/', (req, res) => {
    console.log('[DEBUG] Upload Request Headers:', req.headers);
    console.log('[DEBUG] Content-Type:', req.headers['content-type']);
    if (req.rawBody) {
        console.log('[DEBUG] req.rawBody is present. Length:', req.rawBody.length);
    } else {
        console.log('[DEBUG] req.rawBody is undefined.');
    }

    const busboy = Busboy({
        headers: req.headers,
        limits: {
            fileSize: 5 * 1024 * 1024 // 5MB
        }
    });

    const uploads = {};
    const fileWrites = [];

    busboy.on('file', (fieldname, file, info) => {
        console.log(`[DEBUG] File [${fieldname}]: filename: ${info.filename}, encoding: ${info.encoding}, mimetype: ${info.mimeType}`);

        // buffer the file stream
        const chunks = [];
        file.on('data', (data) => {
            chunks.push(data);
        });

        const filePromise = new Promise((resolve, reject) => {
            file.on('end', () => {
                const buffer = Buffer.concat(chunks);
                console.log(`[DEBUG] File [${fieldname}] Finished. Size: ${buffer.length}`);

                // Upload to Cloudinary
                const stream = cloudinary.uploader.upload_stream(
                    { folder: 'finolex-canteen/receipts', resource_type: 'auto' },
                    (error, result) => {
                        if (result) {
                            console.log('[DEBUG] Cloudinary Success:', result.secure_url);
                            resolve({ url: result.secure_url });
                        } else {
                            console.error('[DEBUG] Cloudinary Error:', error);
                            reject(error);
                        }
                    }
                );
                stream.end(buffer);
            });

            file.on('limit', () => {
                reject(new Error('File size limit exceeded'));
            });
        });

        fileWrites.push(filePromise);
    });

    busboy.on('finish', async () => {
        console.log('[DEBUG] Busboy parsing finished.');
        try {
            const results = await Promise.all(fileWrites);
            if (results.length > 0) {
                res.json({
                    message: 'File uploaded successfully',
                    fileUrl: results[0].url
                });
            } else {
                res.status(400).json({ message: 'No file uploaded' });
            }
        } catch (err) {
            console.error('[DEBUG] Upload failed:', err);
            res.status(500).json({ message: 'Upload failed', error: err.message });
        }
    });

    busboy.on('error', (err) => {
        console.error('[DEBUG] Busboy error:', err);
        if (!res.headersSent) {
            res.status(500).json({ message: 'Parsing Error', error: err.message });
        }
    });

    if (req.rawBody) {
        busboy.end(req.rawBody);
    } else {
        req.pipe(busboy);
    }
});

module.exports = router;
