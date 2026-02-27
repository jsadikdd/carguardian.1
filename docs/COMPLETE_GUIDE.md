# CarGuardian — Complete Setup & Deployment Guide

## Architecture Overview

```
CarGuardian
├── Flutter App (Android APK)
│   ├── Firebase Auth
│   ├── Firestore (data)
│   ├── Firebase Storage (images)
│   └── Flask API (AI analysis)
│
└── Flask Backend (Python)
    ├── OpenAI Vision API
    ├── Firebase Admin SDK
    └── Render / Railway deployment
```

---

## STEP 1 — Firebase Project Setup

### 1.1 Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click **Add Project** → name it `carguardian`

### 1.2 Enable Services
- **Authentication** → Email/Password → Enable
- **Firestore** → Create database → Production mode → `asia-south1`
- **Storage** → Get Started

### 1.3 Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 1.4 Storage Security Rules
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /damage_images/{userId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 1.5 Service Account Key (for Backend)
Project Settings → Service Accounts → Generate new private key
→ Save as `backend/firebase_credentials.json`

### 1.6 Register Android App
Project Settings → Add App → Android
- Package name: `com.carguardian.app`
- Download `google-services.json` → place in `flutter/android/app/`

---

## STEP 2 — Flutter Setup

### 2.1 Prerequisites
```bash
flutter --version   # 3.x.x
dart pub global activate flutterfire_cli
```

### 2.2 Install dependencies
```bash
cd flutter/
flutter pub get
```

### 2.3 Configure Firebase
```bash
firebase login
flutterfire configure --project=YOUR_PROJECT_ID
```
This generates `lib/firebase_options.dart` with real values.

### 2.4 Create asset directories
```bash
mkdir -p assets/images assets/animations assets/fonts
```

---

## STEP 3 — Backend Setup

### 3.1 Local development
```bash
cd backend/
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env    # fill in your values
python app.py
```

### 3.2 .env values
```
OPENAI_API_KEY=sk-proj-...
FIREBASE_CREDENTIALS_PATH=firebase_credentials.json
FIREBASE_STORAGE_BUCKET=carguardian-xxxxx.appspot.com
PORT=5000
```

---

## STEP 4 — Deploy to Render

1. Push `backend/` to GitHub
2. Render.com → New Web Service → connect repo
3. Build command: `pip install -r requirements.txt`
4. Start command: `gunicorn app:app -c gunicorn.conf.py`
5. Environment Variables:
   - `OPENAI_API_KEY`
   - `FIREBASE_CREDENTIALS_JSON` (paste entire JSON string)
   - `FIREBASE_STORAGE_BUCKET`
6. Deploy → note your URL

### Update Flutter API URL
In `lib/utils/constants.dart`:
```dart
static const String apiBaseUrl = 'https://carguardian-api.onrender.com';
```

---

## STEP 5 — Build Android APK

### Debug APK
```bash
cd flutter/
flutter build apk --debug
# → build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```bash
# Generate keystore
keytool -genkey -v \
  -keystore carguardian-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias carguardian

# Build
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Install on device
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## Firestore Data Structure

```
users/{userId}/fleet/{vehicleId}
  name, brand, model, registration_number
  fuel_type, mileage, insurance_expiry_date
  last_service_date, total_repair_cost, vehicle_health_score

  damageReports/{reportId}
    image_url, analysis{}, created_at, language

  serviceRecords/{recordId}
    service_type, service_date, cost, notes, mileage_at_service
```

---

## API Reference

All endpoints require: `Authorization: Bearer <Firebase_ID_Token>`

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/damage/analyze` | AI damage analysis |
| POST | `/api/assistant/query` | Voice assistant |
| GET | `/api/fleet/summary` | Fleet analytics |
| POST | `/api/fleet/{vehicleId}/service` | Add service record |

### POST /api/damage/analyze
```
multipart/form-data:
  image       : file
  vehicle_id  : string
  language    : en | hi | ta

Response:
{
  "analysis": {
    "damage_type": "Dent",
    "severity_level": "Moderate",
    "affected_part": "Front bumper",
    "repair_suggestion": "...",
    "estimated_repair_cost": {"min": 3000, "max": 8000, "currency": "INR"},
    "parts_possibly_required": ["Bumper", "Paint"],
    "confidence_score": 92
  }
}
```

---

## Production Checklist

- [ ] Replace `firebase_options.dart` with real values
- [ ] Add `google-services.json` to `android/app/`
- [ ] Set environment variables on Render/Railway
- [ ] Update `constants.dart` with deployed API URL
- [ ] Set Firestore and Storage security rules
- [ ] Generate release keystore
- [ ] Test on physical Android device (min API 23)
- [ ] Verify notifications on Android 13+
