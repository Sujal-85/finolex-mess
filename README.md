<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Finolex Canteen Messaging System - Project Documentation</title>
    <style>
        :root {
            --primary: #2563eb;
            --secondary: #1e293b;
            --accent: #0f172a;
            --bg: #f8fafc;
            --text: #334155;
            --code-bg: #1e293b;
            --code-text: #e2e8f0;
        }
        body {
            font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
            line-height: 1.6;
            color: var(--text);
            background-color: var(--bg);
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 20px;
            background: white;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
            min-height: 100vh;
        }
        header {
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 20px;
            margin-bottom: 40px;
        }
        h1 {
            color: var(--secondary);
            font-size: 2.5rem;
            margin: 0;
        }
        h2 {
            color: var(--primary);
            margin-top: 40px;
            font-size: 1.8rem;
            border-left: 5px solid var(--primary);
            padding-left: 15px;
        }
        h3 {
            color: var(--accent);
            margin-top: 25px;
        }
        p {
            margin-bottom: 15px;
        }
        ul {
            margin-bottom: 20px;
        }
        li {
            margin-bottom: 8px;
        }
        code {
            background-color: #f1f5f9;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Consolas', monospace;
            color: #d946ef;
        }
        pre {
            background-color: var(--code-bg);
            color: var(--code-text);
            padding: 20px;
            border-radius: 8px;
            overflow-x: auto;
            font-size: 0.9rem;
        }
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: bold;
            margin-right: 8px;
            color: white;
        }
        .bg-flutter { background-color: #02569B; }
        .bg-node { background-color: #339933; }
        .bg-mongo { background-color: #47A248; }
        .bg-firebase { background-color: #FFCA28; color: black; }
        .bg-n8n { background-color: #EA4B71; }

        .feature-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .feature-card {
            background: #fff;
            border: 1px solid #e2e8f0;
            border-radius: 8px;
            padding: 20px;
            transition: transform 0.2s;
        }
        .feature-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        }
        footer {
            margin-top: 60px;
            text-align: center;
            font-size: 0.9rem;
            color: #94a3b8;
        }
    </style>
</head>
<body>

<div class="container">
    <header>
        <h1>Finolex Canteen System</h1>
        <p>A comprehensive digital solution for optimizing canteen operations at Finolex Academy of Management and Technology.</p>
        <div>
            <span class="badge bg-flutter">Flutter</span>
            <span class="badge bg-node">Node.js</span>
            <span class="badge bg-mongo">MongoDB</span>
            <span class="badge bg-firebase">Firebase</span>
            <span class="badge bg-n8n">n8n Automation</span>
        </div>
    </header>

    <section>
        <h2>Project Overview</h2>
        <p>
            The Finolex Canteen Messaging System works to digitize the interactions between students and the canteen administration. 
            It consists of a high-performance <strong>Flutter Mobile App</strong> for students to view menus, pay dues, and track their monthly status, 
            backed by a robust <strong>Node.js/Express API</strong> handling secure data management, verification, and notifications.
        </p>

        <div class="feature-grid">
            <div class="feature-card">
                <h3>📱 Student App</h3>
                <ul>
                    <li>Secure Login & Registration</li>
                    <li>Digital ID Card Generation</li>
                    <li>Live Menu Updates</li>
                    <li>Payment Integrations (UPI)</li>
                    <li>Real-time Notifications</li>
                </ul>
            </div>
            <div class="feature-card">
                <h3>⚙️ Backend Core</h3>
                <ul>
                    <li>RESTful API Architecture</li>
                    <li>JWT Authentication</li>
                    <li>n8n Email Automation</li>
                    <li>Background Cron Jobs</li>
                    <li>Image Management (Cloudinary)</li>
                </ul>
            </div>
        </div>
    </section>

    <section>
        <h2>Technology Stack</h2>
        
        <h3>Frontend (Mobile)</h3>
        <ul>
            <li><strong>Framework:</strong> Flutter (Dart)</li>
            <li><strong>State Management:</strong> Provider + BLoC (with HydratedBloc for persistence)</li>
            <li><strong>Navigation:</strong> GoRouter</li>
            <li><strong>Networking:</strong> Dio (for API requests)</li>
            <li><strong>Animations:</strong> Lottie</li>
            <li><strong>Background Tasks:</strong> WorkManager + Flutter Local Notifications</li>
        </ul>

        <h3>Backend (Server)</h3>
        <ul>
            <li><strong>Runtime:</strong> Node.js</li>
            <li><strong>Framework:</strong> Express.js</li>
            <li><strong>Database:</strong> MongoDB (via Mongoose ODM)</li>
            <li><strong>Authentication:</strong> Firebase Admin (Phone) + JWT (Session)</li>
            <li><strong>Services:</strong> Cloudinary (Media), Nodemailer/Axios (Email), n8n (Workflows)</li>
        </ul>
    </section>

    <section>
        <h2>Key Features Implementation</h2>

        <h3>1. Multi-Step Registration</h3>
        <p>
            A multi-step registration flow validates users before entry. 
            <ul>
                <li><strong>Email Verification:</strong> Uses an n8n webhook to trigger professional HTML emails with OTPs.</li>
                <li><strong>Phone Verification:</strong> Integrated with Firebase Auth for SMS OTP verification.</li>
                <li><strong>Profile Setup:</strong> Captures Hostel/Day Scholar details and profile photos.</li>
            </ul>
        </p>

        <h3>2. Background Notifications</h3>
        <p>
            The app uses <code>workmanager</code> to periodically poll the backend for new important announcements even when the app is closed, ensuring students never miss critical updates like pending due alerts.
        </p>
    </section>

    <section>
        <h2>Setup Instructions</h2>

        <h3>Prerequisites</h3>
        <ul>
            <li>Flutter SDK (v3.x+)</li>
            <li>Node.js (v18+)</li>
            <li>MongoDB Instance (Local or Atlas)</li>
            <li>Firebase Project Credentials</li>
        </ul>

        <h3>Backend Setup</h3>
        <pre>
# 1. Navigate to server directory
cd server

# 2. Install Dependencies
npm install

# 3. Configure Environment Variables (.env)
PORT=4000
DB_URL=mongodb://...
JWT_SECRET=your_secret
CLOUDINARY_CLOUD_NAME=...
N8N_EMAIL_WEBHOOK_URL=https://...

# 4. Start Development Server
npm run dev
</pre>

        <h3>Mobile App Setup</h3>
        <pre>
# 1. Navigate to root directory
cd finolex_student

# 2. Install Dependencies
flutter pub get

# 3. Run the App
flutter run
</pre>
    </section>

    <footer>
        <p>&copy; 2025 Finolex Canteen Project. Maintained by Sujal-85.</p>
    </footer>
</div>

</body>
</html>
