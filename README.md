# 🍽️ Finolex Canteen System

A comprehensive digital solution for optimizing canteen operations at  
**Finolex Academy of Management and Technology (FAMT)**.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=node.js&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![n8n](https://img.shields.io/badge/n8n-EA4B71?style=for-the-badge&logo=n8n&logoColor=white)

---

## 📌 Project Overview

The **Finolex Canteen Messaging System** digitizes communication and transactions between students and the canteen administration.

It includes:
- 📱 A **Flutter mobile app** for students
- ⚙️ A **Node.js + Express backend**
- 🔔 Automated notifications using **Firebase & n8n**
- 💳 Secure payment and verification workflows

This system improves transparency, efficiency, and user experience in daily canteen operations.

---

## ✨ Features

### 📱 Student Mobile App
- Secure Login & Registration
- Digital ID Card Generation
- Live Menu Updates
- UPI Payment Integration
- Real-time Notifications
- Monthly Due Tracking

### ⚙️ Backend Core
- RESTful API Architecture
- JWT-based Authentication
- Firebase Phone Authentication
- n8n Email Automation
- Background Cron Jobs
- Image Management via Cloudinary

---

## 🧱 Technology Stack

### Frontend (Mobile)
- **Framework:** Flutter (Dart)
- **State Management:** Provider + BLoC  
  *(HydratedBloc for persistence)*
- **Navigation:** GoRouter
- **Networking:** Dio
- **Animations:** Lottie
- **Background Tasks:** WorkManager
- **Notifications:** Flutter Local Notifications

### Backend (Server)
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MongoDB (Mongoose ODM)
- **Authentication:**  
  - Firebase Admin (Phone OTP)  
  - JWT (Session Management)
- **Services:**  
  - Cloudinary (Media Storage)  
  - Nodemailer / Axios (Email)  
  - n8n (Workflow Automation)

---

## 🚀 Key Feature Implementation

### 1️⃣ Multi-Step Registration
A secure, verified onboarding flow:
- **Email Verification:**  
  n8n webhook triggers professional HTML emails with OTP
- **Phone Verification:**  
  Firebase SMS OTP authentication
- **Profile Setup:**  
  Hostel / Day Scholar details with profile photo upload

---

### 2️⃣ Background Notifications
- Uses `workmanager` to poll backend periodically
- Ensures students receive:
  - Pending due alerts
  - Important announcements
- Works even when the app is closed

---

## ⚙️ Setup Instructions

### 🔧 Prerequisites
- Flutter SDK `v3.x+`
- Node.js `v18+`
- MongoDB (Local or Atlas)
- Firebase Project Credentials

---

### 🖥️ Backend Setup

```bash
# Navigate to server directory
cd server

# Install dependencies
npm install

# Configure environment variables (.env)
PORT=4000
DB_URL=mongodb://...
JWT_SECRET=your_secret
CLOUDINARY_CLOUD_NAME=...
N8N_EMAIL_WEBHOOK_URL=https://...

# Start development server
npm run dev
📱 Mobile App Setup
bash
Copy code
# Navigate to app directory
cd finolex_student

# Install dependencies
flutter pub get

# Run the app
flutter run
👨‍💻 Maintainer
Sujal Khedekar
Final Year BE (IT) – FAMT
Passionate about Full Stack Development & AI 🚀

📄 License
This project is developed for academic and educational purposes.

© 2025 Finolex Canteen Project

yaml
Copy code

---

### 🔥 Why this README is strong
- Recruiter-friendly
- Clean GitHub badges
- Clear architecture explanation
- Faculty-approved documentation style
- Startup-level presentation

If you want:
- 📸 screenshots section  
- 🧠 system architecture diagram  
- 🏗️ folder structure  
- 🧪 API documentation section  

Say the word — we’ll level it up 💪😄
