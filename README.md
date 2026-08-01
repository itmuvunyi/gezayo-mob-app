# GezaYo

> **GezaYo** is a production-ready Flutter mobile application engineered for Rwanda's on-demand delivery and logistics sector. Built with Riverpod and Clean Architecture, it provides a unified dual-persona platform connecting **Customers** requesting deliveries with **Riders** managing jobs, real-time navigation, and MTN Mobile Money payouts.

---

## Table of Contents

- [Features & Implemented Functionalities](#features--implemented-functionalities)
  - [Authentication & User Management](#authentication--user-management)
  - [Customer Delivery Lifecycle](#customer-delivery-lifecycle)
  - [Rider Logistics & Operations](#rider-logistics--operations)
  - [Financials & Wallet Management](#financials--wallet-management)
  - [System Services & Support](#system-services--support)
- [Database Architecture](#database-architecture)
  - [Dual-Layer Storage Strategy](#dual-layer-storage-strategy)
  - [Firestore Collections & Schema](#firestore-collections--schema)
  - [Concurrency Control & Atomic Settlement](#concurrency-control--atomic-settlement)
  - [Real-Time Data Streams](#real-time-data-streams)
- [Setup & Installation Instructions](#setup--installation-instructions)
  - [Prerequisites](#prerequisites)
  - [Environment Configuration](#environment-configuration)
  - [Installation Steps](#installation-steps)
  - [Running the App](#running-the-app)
  - [Code Quality & Testing](#code-quality--testing)
- [Repository Structure](#repository-structure)
- [License](#license)

---

## Features & Implemented Functionalities

### Authentication & User Management
- **Dual-Persona Onboarding**: Support for both **Customer** and **Rider** role selection during registration.
- **Multi-Factor Auth Protocols**: Email/Password authentication, Phone OTP verification flow, and Google Sign-In integration (`google_sign_in`).
- **Profile & Security Controls**: Profile avatar management, security center with PIN modification, and language selection.
- **Account Deletion & Data Purge**: Cascading deletion purging user documents, active deliveries, and financial ledgers across Firestore and local storage.

### Customer Delivery Lifecycle
- **Package Booking Engine**: Interactive form for specifying pickup/dropoff locations, package category (*Food*, *Parcel*, *Grocery*, *Other*), weight tiers (*Light <5kg*, *Medium 5-15kg*, *Heavy >15kg*), and special instructions.
- **Dynamic Fare Estimation**: Automatic fare calculation in Rwandan Francs (RWF) based on package criteria.
- **Rider Matching**: Real-time algorithm searching nearby online riders with visual searching progress indicators.
- **Live Map Tracking**: Interactive OpenStreetMap implementation (`flutter_map` with `latlong2`) rendering live rider location markers, animated route paths, estimated arrival times, and one-tap driver calling.
- **Order Completion & Feedback**: Delivery confirmation screen featuring tip selection, 1-5 star rider rating system, and automated digital receipts.

### Rider Logistics & Operations
- **Rider Home Dashboard**: Real-time online/offline toggle switch, active job banner, and available jobs feed displaying pickup/dropoff distance and fare payouts.
- **Atomic Job Acceptance**: Race-condition protected job acceptance mechanism (`acceptJobAtomic`) preventing multi-rider claims on single orders.
- **Turn-by-Turn Navigation View**: Dedicated rider route map screen displaying customer contact details, package specifications, and status action buttons (*Mark Picked Up*, *Mark Delivered*).
- **Rider Earnings Dashboard**: Comprehensive financial portal built with `fl_chart` for visual earnings analytics (daily/weekly), job metrics, and history.

### Financials & Wallet Management
- **Customer Wallet & Top-Ups**: Mobile money deposit interface (`/deposit`) supporting MTN Mobile Money and Airtel Money top-up workflows.
- **MTN Mobile Money Rider Payouts**: Automated withdrawal modal allowing riders to request payouts directly to their mobile money accounts.
- **Double-Entry Transaction Ledger**: Immutable logging of job earnings, customer withdrawals, platform bonuses, and deposits (`TransactionModel`).

### System Services & Support
- **Real-Time Notifications Engine**: Dynamic notification feed (`NotificationsScreen`) alerting users to order state changes (*Searching*, *Assigned*, *Picked Up*, *Delivered*, *Completed*).
- **Help Center & Emergency SOS**: Support knowledgebase with searchable FAQ accordions, direct customer care phone/email links, and a high-priority SOS emergency trigger.
- **Multi-Language Localization**: Dynamic translation engine (`translation_service.dart`) supporting English, Kinyarwanda, and French.
- **Declarative Route Guarding**: `GoRouter` redirect guards preventing riders from accessing customer interfaces and vice versa.

---

## Database Architecture

GezaYo utilizes a **Hybrid Dual-Layer Database Architecture** designed for zero-downtime offline reliability and real-time cloud synchronization.

```
                  ┌─────────────────────────────────────┐
                  │          Riverpod Providers         │
                  └──────────────────┬──────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │       FirestoreService          │
                    └────────┬────────────────┬───────┘
                             │                │
          ┌──────────────────▼──────┐  ┌──────▼──────────────────┐
          │  Remote Cloud Database  │  │   Local Offline Cache   │
          │    Firebase Firestore   │  │   DatabaseService (SP)  │
          └─────────────────────────┘  └─────────────────────────┘
```

### Dual-Layer Storage Strategy
1. **Primary Remote Engine (Firebase Cloud Firestore)**: Handles real-time document synchronization (`snapshots()`), atomic state changes, spatial queries, and multi-user transactional integrity.
2. **Local Persistence Engine (`DatabaseService` / `SharedPreferences`)**: Acts as a persistent local fallback cache. Reads and writes mirror to local JSON storage, enabling offline operation and graceful degraded functionality when network connectivity is lost.

### Firestore Collections & Schema

#### `users` Collection
Stores user profiles and real-time rider spatial positions.
| Field | Type | Description |
| :--- | :--- | :--- |
| `uid` | String | Unique Firebase authentication ID |
| `fullName` | String | User's complete legal name |
| `email` | String | Email address |
| `phoneNumber` | String | Phone number with country code (+250) |
| `role` | String | User persona (`customer` or `rider`) |
| `avatarUrl` | String | URL to profile picture |
| `rating` | Double | Cumulative performance rating (1.0 - 5.0) |
| `totalDeliveries`| Int | Count of completed delivery orders |
| `isOnline` | Boolean | Online availability status (riders) |
| `latitude` | Double | Real-time GPS latitude coordinate |
| `longitude` | Double | Real-time GPS longitude coordinate |

#### `deliveries` Collection
Tracks the full lifecycle state machine for every delivery order.
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique delivery order identifier |
| `customerUid` | String | ID of customer who initiated the order |
| `customerPhone` | String | Contact phone number for customer |
| `pickupAddress` | String | Origin location name / coordinates |
| `dropoffAddress`| String | Destination location name / coordinates |
| `packageType` | String | Category (*Food*, *Parcel*, *Grocery*, *Other*) |
| `weightClass` | String | Weight tier (*Light*, *Medium*, *Heavy*) |
| `instructions` | String | Special handling notes from customer |
| `estimatedFareRwf`| Double | Calculated delivery fee in RWF |
| `status` | String | State machine: `searching` → `assigned` → `pickedUp` → `onTheWay` → `delivered` → `completed` → `cancelled` |
| `assignedRiderUid`| String? | ID of assigned rider |
| `assignedRiderName`| String? | Name of assigned rider |
| `assignedRiderPhone`| String? | Phone number of assigned rider |
| `assignedRiderRating`| Double | Rating of assigned rider |
| `tipAmount` | Double | Gratuity added by customer |
| `ratingGiven` | Int | Rating given by customer post-delivery |
| `createdAt` | String | ISO 8601 creation timestamp |

#### `transactions` Collection
Financial transaction ledger for customer debits and rider credits.
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | String | Unique transaction reference ID |
| `userId` | String | User UID associated with the entry |
| `title` | String | Description (e.g., `Delivery #d-101`) |
| `dateText` | String | Display timestamp |
| `amountRwf` | Double | Transaction value in RWF |
| `type` | String | Category (`jobEarning`, `withdrawal`, `bonus`, `deposit`) |
| `status` | String | Transaction state (`completed`, `processed`, `pending`) |

#### `notifications` Collection
System notifications and delivery event triggers.

---

### Concurrency Control & Atomic Settlement
- **Race Condition Prevention (`acceptJobAtomic`)**: When a rider accepts a job, an atomic Firestore verification checks that `status == 'searching'`. If another rider claimed the job simultaneously, the transaction aborts and returns `false`.
- **Dual-Wallet Atomic Settlement (`confirmDeliveryByCustomer`)**: Upon customer confirmation of delivery receipt, an atomic execution updates the delivery state to `completed`, credits the rider's wallet ledger with `jobEarning`, and debits the customer's wallet ledger with `withdrawal`.

### Real-Time Data Streams
The application binds UI components directly to reactive Firestore streams exposed via Riverpod:
- `getAvailableJobsStream()`: Real-time list of unassigned jobs (`status == 'searching'`). Sorted in Dart memory to eliminate composite index overhead.
- `getOnlineRidersStream()`: Live updates of available riders on the customer map.
- `getDeliveryStream(id)`: Active delivery tracking feed for customer live map updates.
- `getTransactionsStream(userId)`: Live ledger updates for rider and customer wallet screens.

---

## Setup & Installation Instructions

### Prerequisites
Ensure your local development environment meets the following minimum requirements:
- **Flutter SDK**: `>= 3.0.0` (Dart SDK `>= 3.0.0 < 4.0.0`)
- **Android Studio** (with Android SDK & Build Tools) or **Xcode** (for iOS simulator builds)
- **VS Code** with Flutter & Dart extensions (Recommended)

### Environment Configuration
1. Clone or copy the environment configuration template:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and verify/update your Firebase project credentials and API keys:
```env
FIREBASE_PROJECT_ID=gezayo-2179c
FIREBASE_MESSAGING_SENDER_ID=586525703658
FIREBASE_STORAGE_BUCKET=gezayo-2179c.firebasestorage.app

FIREBASE_WEB_API_KEY=AIzaSyA4f0bQIt7Ex3-nZ_dtwA9LzcRgpx4il1M
FIREBASE_WEB_APP_ID=1:586525703658:web:4362c0eb230a857b96c693
FIREBASE_WEB_AUTH_DOMAIN=gezayo-2179c.firebaseapp.com

FIREBASE_ANDROID_API_KEY=AIzaSyDbyNh7NF0XTcpwrsF6YKtAYZq_l7pQ2NE
FIREBASE_ANDROID_APP_ID=1:586525703658:android:34689bce1e46f23596c693

FIREBASE_IOS_API_KEY=AIzaSyCAY1JFJMDR0ib9XQ922myhwIf3GucujCY
FIREBASE_IOS_APP_ID=1:586525703658:ios:e5af38feb988a0b396c693
FIREBASE_IOS_BUNDLE_ID=com.example.gezayoApp

API_BASE_URL=https://api.gezayo.rw/v1
GOOGLE_WEB_CLIENT_ID=586525703658-web-client.apps.googleusercontent.com
```

### Installation Steps
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/GezaYo-App.git
   cd GezaYo-App
   ```

2. **Fetch Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify Firebase Setup**:
   Ensure `lib/firebase_options.dart` matches your configured `.env` file credentials.

### Running the App
Launch the application on an emulator or physically connected target device:

```bash
# Run default target
flutter run

# Run on specific target (e.g. Chrome, Android emulator, iOS simulator)
flutter run -d chrome
flutter run -d android
```

### Code Quality & Testing
Maintain repository code quality using Flutter's CLI toolchain:

```bash
# Run unit and widget tests
flutter test

# Perform static code analysis
flutter analyze

# Enforce code formatting
dart format --set-exit-if-changed .
```

---

## Repository Structure

```
GezaYo-App/
├── .env.example                # Sample environment file template
├── pubspec.yaml                # Dependencies & asset definitions
├── assets/                     # Logos, icons, and static assets
├── lib/
│   ├── main.dart               # App entry point, Firebase init & Riverpod scope
│   ├── firebase_options.dart   # Cross-platform Firebase configuration
│   ├── core/                   # Shared infrastructure & utilities
│   │   ├── constants/          # Brand colors, typography, API routes
│   │   ├── router/             # GoRouter configuration & route guards
│   │   ├── services/           # FirestoreService, DatabaseService, BackendApiService
│   │   ├── theme/              # Custom ThemeData & light/dark modes
│   │   ├── utils/              # Currency/date formatters, validators
│   │   └── widgets/            # Reusable UI components (buttons, badges, inputs)
│   └── features/               # Modular clean-architecture business domains
│       ├── auth/               # Login, signup, phone OTP, role selection
│       ├── customer/           # Booking form, rider matching, live map, rating
│       ├── rider/              # Job feed, navigation, route view, earnings
│       ├── wallet/             # Ledger, fl_chart graphs, MoMo payout modal
│       ├── profile/            # User profile, security center, language screen
│       ├── help/               # Knowledgebase FAQ accordion, SOS trigger
│       └── splash_onboarding/  # Splash screen & onboarding carousel
└── test/                       # Unit and widget test suite
```

---

## License

Distributed under the **MIT License**. See `LICENSE` for more information.
