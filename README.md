# GezaYo — Production-Ready Flutter Delivery Mobile Application

GezaYo is a high-performance, university-grade, production-ready Flutter mobile application designed for Rwanda's fast-growing delivery and logistics sector. The application serves both **Customers** (requesting food, parcel, grocery, and errand deliveries) and **Riders** (accepting jobs, navigating, and managing earnings).

---

## Architecture & Stack Overview

- **Frontend Core**: Flutter (Dart 3) with custom UI tokens, responsive layouts, and zero overflow errors.
- **State Management**: Flutter Riverpod (`StateNotifierProvider`) with immutable state transitions.
- **Navigation**: `GoRouter` declarative routing engine with deep linking support.
- **Data & Storage Layer**: Clean Repository pattern (`AuthRepository`, `DeliveryRepository`, `RiderRepository`) with `SharedPreferences` persistence.
- **Backend API & DB Engine**: Production-ready `BackendApiService` with REST endpoint emulation (`GET`, `POST`, `PUT`, `DELETE`), status codes (`200`, `201`, `400`, `404`), error handling, and `DatabaseService` seed data.

---

## Prototype Screens Implemented (17 Screens)

1. **Splash Screen** — Logo, curved gradient header, central badge, version label.
2. **Onboarding Carousel** — 3-stage feature slider with custom pill indicators.
3. **Auth Screen** — Dual authentication (Email/Password & Phone OTP with +250 picker), Google Sign-In, Role Switcher (Customer/Rider).
4. **Customer Home Dashboard** — Search bar, 2x2 service grid, radar scan map, floating "Send Now" button.
5. **Create Delivery Request** — Pickup/Dropoff inputs, package type selector, weight class pills, optional notes.
6. **Rider Matching** — Radar scan animation, bottom sheet with Auto-assign & Manual rider selection cards.
7. **Live Tracking (Customer)** — Floating arrival card, 4-step progress stepper, 3D map polyline, rider call/chat.
8. **Order Completion** — Confetti celebration animation, itemized summary, 5-star rating, tip pills with Mobile Money.
9. **Rider Home Dashboard** — ONLINE/OFFLINE toggle, statistics, available job feed with route preview.
10. **Delivery Job Details** — Customer contact, pickup/dropoff breakdown, instructions, payment breakdown.
11. **Rider Navigation** — Turn-by-turn banner, route polyline, customer tile, "Picked Up / Complete" CTAs.
12. **Rider Earnings** — Total balance banner, Mobile Money withdrawal modal, `fl_chart` daily/weekly bar graph, transaction history.
13. **Profile Screen** — Avatar badge, review quote card, mode toggle, language selector, notifications link.
14. **Help Center** — Emergency button, WhatsApp/Email support, issue report, FAQ accordion.
15. **Notifications Screen** — Delivery alerts, promo toggles, unread notifications list.
16. **Security Screen** — Change password dialog, 2FA, Biometric lock, active sessions, Delete account.
17. **Language Screen** — Multi-language selector (English, Kinyarwanda, Français, Kiswahili) with instant app state sync.

---

## Testing & Code Verification

To run unit and widget tests:
```bash
flutter test
```

To run static code analysis:
```bash
flutter analyze
```
