# OPD Queue Management System
**IT3060 - Human Computer Interaction | WD_40**

A mobile application to improve appointment booking and queue management in Government Hospital OPDs.

---

## Team Members

| IT Number | Name | Branch | Role |
|---|---|---|---|
| IT23829060 | BMTP MENDIS | `feature/staff-walkin-queue-management` | Staff / Nurse |
| IT23823570 | W.M.P Weerasooriya | `feature/patient-appointment-booking` | Patient |
| IT23834842 | NN WIJESINGHE | `feature/doctor-consultation-queue` | Doctor |
| IT23834392 | RKAM Deshan | `feature/admin-dashboard-reporting` | Admin |

---

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Node.js + Express
- **Database:** MongoDB

---

## Branch Structure

```
main          → final production code
└── dev       → integration branch (merge your feature here)
    ├── feature/patient-appointment-booking
    ├── feature/doctor-consultation-queue
    ├── feature/admin-dashboard-reporting
    └── feature/staff-walkin-queue-management
```

> Never push directly to `main`. Always work on your feature branch and merge into `dev`.

---

## Prerequisites

Make sure you have these installed before setting up:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or above)
- [Dart SDK](https://dart.dev/get-dart) (comes with Flutter)
- [Node.js](https://nodejs.org/) (v18 or above)
- [MongoDB](https://www.mongodb.com/try/download/community) (local) or a MongoDB Atlas account
- [Git](https://git-scm.com/)
- [Android Studio](https://developer.android.com/studio) with Flutter & Dart plugins (recommended)
- or [VS Code](https://code.visualstudio.com/) with Flutter & Dart extensions

---

## Project Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd IT3060-HCI-Mobile-APP--WD40
```

### 2. Checkout Your Branch

```bash
git fetch --all
git checkout feature/<your-branch-name>
```

### 3. Flutter Frontend Setup

```bash
cd app/frontend/opd_queue_app
flutter pub get
flutter run
```

### 4. Backend Setup

```bash
cd app/backend
npm install
```

Create a `.env` file inside `app/backend/`:

```
PORT=5000
MONGO_URI=mongodb://localhost:27017/opd_queue_db
```

Then start the server:

```bash
npm start
```

---

## Git Workflow

```bash
# 1. Always pull latest dev before starting work
git checkout dev
git pull origin dev

# 2. Switch to your feature branch
git checkout feature/<your-branch-name>

# 3. Merge latest dev into your branch
git merge dev

# 4. Do your work, then commit
git add .
git commit -m "feat: your message here"

# 5. Push your branch
git push origin feature/<your-branch-name>

# 6. Create a Pull Request into dev on GitHub
```

---

## Folder Structure

```
app/
├── backend/               → Node.js + Express API
└── frontend/
    └── opd_queue_app/
        └── lib/
            └── features/
                ├── patient/     → W.M.P Weerasooriya
                ├── doctor/      → NN WIJESINGHE
                ├── staff/       → BMTP MENDIS
                └── admin/       → RKAM Deshan
```

---

## Contact

For any setup issues contact the team leader: **BMTP MENDIS (IT23829060)**
