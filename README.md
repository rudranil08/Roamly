# Roamly

> Turn your journeys into a personal travel logbook.

Roamly is an iOS travel companion that records your spontaneous trips for you. It notices when you leave home and detects meaningful places you visit, like museums, parks and landmarks. It then asks you to confirm each visit with a photo and turns your adventures into memories and points.

**Status:** in active development.

## Features

- **Automatic place detection.** A dwell-detection state machine watches for departures from your home geofence. When you stay somewhere, it resolves the venue through MapKit and sends a notification asking you to confirm.
- **Logbook.** Every confirmed visit is saved with its photo, place, category, travel mode and spend.
- **Explore map** of everywhere you've been.
- **Scoring** for each visit, based on novelty, distance (sub-linear and capped), how significant the place is (World Heritage sites score higher than shopping centres) and how sustainably you got there.
- **Explorer levels, streaks and badges,** plus an eco-impact strip that estimates the CO₂ you avoided by walking, cycling or taking public transport.
- **Anti-cheat.** Duplicate photos are caught with a 64-bit perceptual hash (dHash). Visits are also checked for impossible travel speeds ("teleporting") and low GPS accuracy.
- **Offline-first sync.** Visits are stored locally with SwiftData and queued for cloud sync (Supabase), so they upload when you're back online.
- **Onboarding and settings:** home location, permissions, currency, appearance, accessibility and notifications.

## Tech

| | |
|---|---|
| UI | SwiftUI, iOS 27 |
| State | `@Observable` |
| Storage | SwiftData |
| Location | Core Location (geofencing, visits), MapKit (venue lookup), Core Motion (travel mode) |
| Camera | AVFoundation |
| Sync | Supabase (optional; a demo mode simulates the cloud) |
| Notifications | UserNotifications |

No third-party packages.

## Project layout

```
Roamly/
├── App/            App state
├── Core/
│   ├── Camera/         Capture and photo storage
│   ├── Location/       Location, motion and destination detection
│   ├── Models/         Places, categories, travel modes
│   ├── Notifications/
│   ├── Persistence/    SwiftData container and entities
│   ├── Scoring/        Scoring, levels, streaks, badges
│   ├── Security/       Anti-cheat and perceptual hashing
│   ├── Settings/       Currency and user settings
│   └── Sync/           Supabase sync queue
├── Features/       Camera, Dashboard, Home, Leaderboard, Logbook, Onboarding, Settings
└── Shared/         Theme and shared views
```

## Run it

1. Open `Roamly.xcodeproj` in Xcode with the iOS 27 SDK.
2. Choose a simulator or device and press **⌘R**.

Place detection relies on real location and motion data, so it works best on a physical iPhone. In the simulator, use **Features › Location** to simulate movement.

Cloud sync starts in demo mode. To use your own Supabase project, enter its URL and anon key in **Settings › Cloud Journal Sync**.

## Author

Rudranil Dhol · [GitHub](https://github.com/rudranil08) · [LinkedIn](https://www.linkedin.com/in/rudranil-dhol-1222a3360/)
