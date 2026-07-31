# GezaYo

> **GezaYo** is a production-ready Flutter mobile application engineered for Rwanda's on-demand delivery and logistics sector. Built with Riverpod and Clean Architecture, it provides a unified dual-persona platform connecting **Customers** requesting deliveries with **Riders** managing jobs, real-time navigation, and MTN Mobile Money payouts.

---

## Repository Structure

```
GezaYo-App/
├── .env.example                # Sample environment file template
├── API_documentation.md        # Comprehensive REST API contracts & JSON schemas
├── pubspec.yaml                # Project dependencies & asset declarations
├── assets/                     # Graphic assets, logos, and icons
├── lib/
│   ├── main.dart               # Entry point, Firebase init & Riverpod ProviderScope
│   ├── firebase_options.dart   # Firebase configuration matrix
│   ├── core/                   # Shared cross-cutting concerns
│   │   ├── constants/          # App colors, typography, and API endpoints
│   │   ├── router/             # GoRouter configuration & route paths
│   │   ├── services/           # BackendApiService & DatabaseService seed engine
│   │   ├── theme/              # Custom ThemeData & light/dark color tokens
│   │   ├── utils/              # Formatters, validators, and date helpers
│   │   └── widgets/            # Reusable UI buttons, badges, navigation bars, and inputs
│   └── features/               # Feature-first modular business logic
│       ├── auth/               # Auth controllers, login/signup UI, role providers
│       ├── customer/           # Customer dashboard, booking form, rider matching, live map
│       ├── rider/              # Rider dashboard, job details, navigation, route view
│       ├── wallet/             # Earnings ledger, fl_chart graphs, MoMo payout modal
│       ├── profile/            # User settings, security center, language screen
│       ├── help/               # Support center, SOS emergency trigger, FAQ accordion
│       └── splash_onboarding/  # Splash screen & interactive onboarding carousel
└── test/                       # Unit and widget test suite
```

---

### Prerequisites

Ensure your local development environment meets the following requirements:
- **Flutter SDK**: `>= 3.0.0` (Dart SDK `>= 3.0.0 < 4.0.0`)
- **Android Studio** / **Xcode** (for iOS simulator builds)
- **VS Code** with Flutter & Dart extensions (Recommended)

### Installation & Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/GezaYo-App.git
   cd GezaYo-App
   ```

2. **Configure Environment Variables**:
   Copy `.env.example` to create `.env`:
   ```bash
   cp .env.example .env
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Launch the Application**:
   ```bash
   # Run on connected device or emulator
   flutter run
   ```

---

## Testing & Code Verification

Maintain code quality and ensure regression-free builds using Flutter's built-in toolchain:

- **Run Unit & Widget Tests**:
  ```bash
  flutter test
  ```

- **Run Static Code Analysis**:
  ```bash
  flutter analyze
  ```

- **Enforce Code Formatting**:
  ```bash
  dart format --set-exit-if-changed .
  ```
## License

Distributed under the **MIT License**. See `LICENSE` for more information.