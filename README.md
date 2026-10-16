# MessLife

A Flutter and Firebase mobile app for finding and managing shared-living households (mess) in Bangladesh.

Developed for CSE 328: Software Engineering Lab, Department of CSE, Bangladesh University of Business and Technology (BUBT).

## Overview

Mess residents in Bangladesh usually track meals, groceries, and payments using notebooks and chat groups. This leads to errors and disputes. MessLife provides one real-time platform for the whole mess lifecycle: finding a mess, joining it, tracking meals and expenses, recording payments, and generating monthly summaries.

## Features

- Map-based mess discovery with filters and geohash proximity search
- Join requests with admin approval
- Meal tracking with autopilot mode, per-member overrides, and guest meals
- Bazar (grocery) expense tracking with optional approval and receipt upload
- Payment records for rent, deposit, utility, bazar settlement, and others, with PDF receipts
- Notice board with priority levels and pinning
- One-to-one chat with text and image support
- Monthly summary with per-member dues and PDF export
- Statistics dashboard for meal and expense trends
- Room, seat, and to-let listing management
- Activity log for all major actions
- Role-based access control (Admin, Manager, Member)
- Push notifications using Firebase Cloud Messaging

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x (Dart ^3.12) |
| Authentication | Firebase Authentication (email, Google, phone OTP) |
| Database | Cloud Firestore |
| Image Storage | Cloudinary |
| Notifications | Firebase Cloud Messaging |
| Maps and Location | MapLibre GL, geolocator, latlong2 |
| PDF | pdf, printing |

## Getting Started

### Prerequisites

- Flutter SDK 3.x
- Android Studio or VS Code
- A Firebase project
- A Cloudinary account

### Installation

```bash
git clone <repository-url>
cd messlife
flutter pub get
```

### Firebase Setup

1. Create a Firebase project and enable Authentication, Cloud Firestore, and Cloud Messaging.
2. Generate the Firebase configuration:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

3. Add your SHA-1 and SHA-256 fingerprints in the Firebase Console.
4. Deploy the Firestore Security Rules.

### Cloudinary Setup

Add your Cloudinary cloud name and upload preset in the project's Cloudinary service file. Do not commit secret keys to the repository.

### Run

```bash
flutter run
```

## Team

Section 05, Intake 53

| Name | ID |
|------|----|
| Md. Mashiur Rahman | 20245103175 |
| Tahsin Ahammed Alvi | 20245103187 |
| Md. Akif Uz Zaman | 20245103190 |
| Baized Al Basher | 20245103197 |

Supervisor: Nahida Akter Tanjila (NAT), Lecturer, Department of CSE, BUBT
