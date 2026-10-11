# OPD Queue Management System
> **IT3060 - Human Computer Interaction** — 3rd Year, Semester 2 @ SLIIT
> A mobile application to improve appointment booking and queue management in Government Hospital OPDs.

![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B)
![Dart](https://img.shields.io/badge/Dart-Language-0175C2)
![Node.js](https://img.shields.io/badge/Node.js-Backend-339933)
![MongoDB](https://img.shields.io/badge/MongoDB-Database-47A248)

---

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [User Roles](#user-roles)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Running the Project](#running-the-project)
- [Team Workflow & Git Guidelines](#team-workflow--git-guidelines)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Overview

**OPD Queue Management System** is a mobile application designed to improve appointment booking and queue management in Government Hospital Outpatient Departments (OPDs).

### Key Objectives
✅ **Reduce Waiting Times** — Digital queue management to minimize patient waiting  
✅ **Online Appointment Booking** — Patients can book appointments without visiting the hospital  
✅ **Real-Time Queue Tracking** — Live queue status for patients and staff  
✅ **Staff Management** — Tools for staff to manage walk-ins and queue flow  
✅ **Admin Oversight** — Administrators can monitor OPD operations and patient flow  

---

## ✨ Features

### For Patients
- 📅 **Appointment Booking** — Book OPD appointments online
- 🔢 **Queue Tracking** — View real-time queue position and estimated wait time
- 🔔 **Notifications** — Receive alerts for appointment reminders and queue updates
- 📋 **Appointment History** — View upcoming and past appointments

### For Staff / Nurses
- 🧾 **Walk-In Booking** — Issue walk-in tickets for patients at the OPD desk
- 📋 **Daily Register** — View, search, update and cancel daily bookings
- 📺 **Live Queue Board** — Monitor real-time queue across all rooms
- 🔄 **Status Updates** — Progress patient status through consultation stages

### For Doctors
- 📅 **Consultation Schedule** — View daily appointment list
- 🔢 **Queue Management** — Manage patient consultation flow

### For Administrators
- 📊 **OPD Dashboard** — Monitor bookings, cancellations and patient flow
- ⚙️ **Schedule Management** — Manage OPD schedules, doctors and slots
- 📈 **Reports** — View operational reports and analytics

---

## 🛠 Tech Stack

### Frontend
- **Flutter** — Cross-platform mobile application framework
- **Dart** — Programming language for Flutter

### Backend
- **Node.js** — JavaScript runtime environment
- **Express.js** — Web application framework for Node.js

### Database
- **MongoDB** — NoSQL database for storing patient and booking data

---

## 👥 User Roles

| Role | Branch | Member | Key Features |
|------|--------|--------|--------------|
| **Patient** | `feature/patient-appointment-booking` | W.M.P Weerasooriya | Book appointments, track queue |
| **Doctor** | `feature/doctor-consultation-queue` | NN WIJESINGHE | View schedule, manage consultations |
| **Staff / Nurse** | `feature/staff-walkin-queue-management` | BMTP MENDIS | Walk-in bookings, live queue |
| **Admin** | `feature/admin-dashboard-reporting` | RKAM Deshan | Monitor OPD, manage operations |

---

## 📁 Project Structure

```
app/
├── backend/                    → Node.js + Express API
│   ├── models/                 → MongoDB models
│   ├── routes/                 → API routes
│   ├── controllers/            → Business logic
│   └── server.js               → Entry point
└── frontend/
    └── opd_queue_app/
        └── lib/
            ├── main.dart
            └── features/
                ├── patient/    → W.M.P Weerasooriya
                │   ├── models/
                │   ├── screens/
                │   ├── services/
                │   └── widgets/
                ├── doctor/     → NN WIJESINGHE
                │   ├── models/
                │   ├── screens/
                │   ├── services/
                │   └── widgets/
                ├── staff/      → BMTP MENDIS
                │   ├── models/
                │   ├── screens/
                │   ├── services/
                │   └── widgets/
                └── admin/      → RKAM Deshan
                    ├── models/
                    ├── screens/
                    ├── services/
                    └── widgets/
```

---

## 📦 Prerequisites

Before starting development, ensure you have the following installed:

| Tool | Version | Purpose | Check |
|------|---------|---------|-------|
| **Flutter SDK** | 3.x+ | Mobile framework | `flutter --version` |
| **Dart SDK** | 3.x+ | Comes with Flutter | `dart --version` |
| **Node.js** | v18+ | Backend runtime | `node -v` |
| **npm** | v9+ | Package manager | `npm -v` |
| **MongoDB** | 6+ | Database | `mongod --version` |
| **Git** | Any | Version control | `git --version` |

**IDE:** Android Studio or VS Code with Flutter & Dart extensions

---

## 🚀 Quick Start

### 1️⃣ Clone the Repository
```bash
git clone <your-repo-url>
cd IT3060-HCI-Mobile-APP--WD40
```

### 2️⃣ Checkout Your Branch
```bash
git fetch --all
git checkout feature/<your-branch-name>
```

### 3️⃣ Flutter Frontend Setup
```bash
cd app/frontend/opd_queue_app
flutter pub get
flutter run
```

### 4️⃣ Backend Setup
```bash
cd app/backend
npm install
```

Create a `.env` file inside `app/backend/`:
```env
PORT=5000
MONGO_URI=mongodb://localhost:27017/opd_queue_db
```

Start the backend server:
```bash
npm start
```

---

## ▶️ Running the Project

### Flutter App
```bash
cd app/frontend/opd_queue_app
flutter run -d chrome        # Run on Chrome (development)
flutter run                  # Run on connected device/emulator
```

### Backend Server
```bash
cd app/backend
npm start                    # Start server on port 5000
npm run dev                  # Start with nodemon (auto-restart)
```

---

## 🔧 Team Workflow & Git Guidelines

### Branch Structure
```
main          → final production code (never push directly)
└── dev       → integration branch (merge your feature here)
    ├── feature/patient-appointment-booking
    ├── feature/doctor-consultation-queue
    ├── feature/admin-dashboard-reporting
    └── feature/staff-walkin-queue-management
```

### Daily Workflow
```bash
# 1. Pull latest dev before starting work
git checkout dev
git pull origin dev

# 2. Switch to your feature branch
git checkout feature/<your-branch-name>

# 3. Merge latest dev into your branch
git merge dev

# 4. Do your work, commit in small logical parts
git add <specific-file>
git commit -m "feat(role): short description of change"

# 5. Push your branch
git push origin feature/<your-branch-name>

# 6. Open a Pull Request into dev on GitHub
```

### Commit Message Format
```
feat(staff): add walk-in booking screen
feat(patient): add appointment booking form
fix(doctor): fix queue display issue
chore: update dependencies
```

### Rules
- ❌ Never push directly to `main`
- ❌ Never touch another member's feature folder
- ❌ Never commit `.env` files
- ✅ Always work inside your own `features/<role>/` folder
- ✅ Make small, meaningful commits
- ✅ Pull from `dev` before starting new work

---

## 🆘 Troubleshooting

### ❌ `No pubspec.yaml file found`
You are running Flutter from the wrong folder. Run from inside the Flutter project:
```bash
cd app/frontend/opd_queue_app
flutter run
```

### ❌ `Failed to fetch` API errors
Backend server is not running. Start it:
```bash
cd app/backend
npm start
```

### ❌ Flutter build folder locked (OneDrive issue)
Run the app from a non-OneDrive location:
```bash
cd C:\Projects\IT3060-HCI-Mobile-APP--WD40\app\frontend\opd_queue_app
flutter run -d chrome
```

### ❌ `flutter pub get` fails
Check your Flutter SDK installation:
```bash
flutter doctor
```

---

## 📞 Support & Questions

For setup issues contact the team leader: **BMTP MENDIS (IT23829060)**

---

## ✍️ Authors

**WD_40 — OPD Queue Management Team**  
SLIIT — 3rd Year, Semester 2 (2026)

| IT Number | Name |
|-----------|------|
| IT23829060 | BMTP MENDIS |
| IT23823570 | W.M.P Weerasooriya |
| IT23834842 | NN WIJESINGHE |
| IT23834392 | RKAM Deshan |

---

**Last Updated:** October 2026  
**Module:** IT3060 - Human Computer Interaction
