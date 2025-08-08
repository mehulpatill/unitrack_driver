# UniTrack Driver

UniTrack Driver is a modern Flutter application for managing and tracking drivers and vehicles (buggies) in a university or campus setting. It provides real-time location tracking, boundary enforcement, admin dashboards, and seamless authentication using Supabase.

---

## Table of Contents
- [Features](#features)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
  - [1. Prerequisites](#1-prerequisites)
  - [2. Supabase Setup](#2-supabase-setup)
  - [3. Setting Map Boundaries](#3-setting-map-boundaries)
  - [4. Running the App](#4-running-the-app)
- [Usage](#usage)
- [Project Structure](#project-structure)


---

## Features

- **Supabase Auth Integration**: Secure driver and admin authentication.
- **Real-Time Location Tracking**: Track driver locations with automatic updates.
- **Map Boundary Enforcement**: Vehicles are restricted to preset boundaries.
- **Admin Dashboard**: Manage drivers, vehicles, and system stats.
- **Driver Home**: Buggy assignment, location status, and map view.
- **Cross-platform**: Works on Android, iOS, Web, Windows, Linux.

---

## Architecture Overview

- **Dart/Flutter**: Frontend and UI
- **Supabase**: Authentication, database, and real-time updates
- **Map System**: Utilizes `flutter_osm_plugin` with boundary enforcement via constants

**Main Flow**:
1. App reads Supabase credentials and boundary values from `lib/config/constant.dart`.
2. On startup, initializes Supabase (see `lib/main.dart`).
3. Users (drivers/admins) authenticate and are routed to their respective dashboards.
4. Drivers are tracked via geolocation; admins manage driver and buggy assignments.
5. Map widgets enforce boundaries using constants.

---

## Getting Started

### 1. Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) SDK
- [Dart](https://dart.dev/get-dart)
- A [Supabase](https://supabase.com/) project with `drivers` and `admin` tables set up.

### 2. Supabase Setup

Before running the app, you **must** provide your Supabase Project URL and Anon Key.

Open `lib/config/constant.dart` and set:
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 3. Setting Map Boundaries

Boundaries restrict where vehicles can operate on the map. Adjust these values in `lib/config/constant.dart`:
```dart
const double northBoundary = 22.29539;
const double southBoundary = 22.28473;
const double eastBoundary  = 73.36750;
const double westBoundary  = 73.35855;
```
> **Tip:** Set these to your campus or site’s geographical coordinates.

### 4. Running the App

```bash
flutter pub get
flutter run
```

---

## Usage

- **First-time setup:** Supply your Supabase credentials and boundary coordinates.
- **Admins:** After login, access the dashboard to manage drivers and vehicles.
- **Drivers:** Register, get assigned a buggy, and enable location tracking. The map view will show your location, restricted to defined boundaries.
- **Map boundaries:** Toggle on/off in the map UI. When enabled, driver’s location and buggy movement are limited to your specified area.

---

## Project Structure

- `lib/config/constant.dart` — Supabase config, boundaries
- `lib/main.dart` — App entrypoint and Supabase initialization
- `lib/screens/` — UI screens (login, register, admin dashboard, driver home, buggy management)
- `lib/services/` — Business logic (auth, location sending, admin actions)
- `lib/widgets/map.dart` — Map UI, boundary controls, location tracking
