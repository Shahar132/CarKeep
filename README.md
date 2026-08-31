# CarKeep

CarKeep is a Flutter application for managing the complete lifecycle of one or more vehicles in a shared digital space.

The goal is to keep vehicle information, maintenance history, insurance, annual tests, licenses, documents, and shared access all in one organized place.

## Features

### Vehicle Management

Users can create and manage multiple vehicles with information such as:

- License plate number
- Manufacturer
- Model
- Year
- Current mileage

Each vehicle has its own digital record containing current information, history, documents, and shared users.

### Vehicle Overview

Important vehicle information is displayed directly on the home screen:

- Annual vehicle test expiry
- Vehicle license expiry
- Insurance expiry
- Service information

Each section can be individually shown or hidden.

### Vehicle History

CarKeep maintains a history of important vehicle events:

- Services
- Annual tests
- Vehicle license renewals
- Insurance renewals
- Repairs
- Other events

The current vehicle state is calculated from its history. For example, if the latest vehicle license renewal is deleted, CarKeep automatically restores the previous renewal as the current one.

### Documents

Vehicle documents are organized into categories:

- Vehicle licenses
- Annual tests
- Insurance
- Services
- Other documents

Documents can also be uploaded directly while adding a vehicle event. In that case, CarKeep automatically links the document to the event and generates an appropriate document name.

Documents are stored using Supabase Storage.

### Shared Vehicle Access

A vehicle can be shared between multiple users. CarKeep supports three roles:

| Role   | View | Edit Vehicle Data | Manage Events & Documents | Manage Members | Delete Vehicle |
|--------|:----:|:------------------:|:--------------------------:|:---------------:|:---------------:|
| Owner  | ✅   | ✅                  | ✅                          | ✅               | ✅               |
| Admin  | ✅   | ✅                  | ✅                          | ❌               | ❌               |
| Member | ✅   | ❌                  | ❌                          | ❌               | ❌               |

Each vehicle has one owner. The owner can:

- Add and remove users
- Change user roles
- Promote members to admins
- Transfer vehicle ownership

### Service Tracking

CarKeep tracks services using both date and mileage. For example:

```text
Last service: 60,000 km
Service interval: 15,000 km
Next service: 75,000 km
```

It also calculates the next expected service date.

### Account Management

Users can:

- Register and log in
- Update their name
- Change their password
- Sign out
- Delete their account

Account deletion also takes shared vehicle ownership into account — a user who owns a shared vehicle must transfer ownership before deleting the account.

## Technology Stack

**Frontend**
- Flutter
- Dart
- Material Design

**Backend**
- Supabase
- PostgreSQL
- Supabase Authentication
- Supabase Storage
- Row Level Security
- Edge Functions

## Architecture

The project is divided into separate layers for:

- Models
- Repositories
- Business logic and utilities
- Screens
- Reusable widgets
- Navigation

```text
lib/
├── models/
├── repositories/
├── screens/
├── theme/
├── utils/
├── widgets/
├── app_navigation.dart
└── main.dart
```

Automated unit and widget tests are included for the main application logic and UI flows.

## Current Status

CarKeep is currently under active development. The main application flows are implemented. The current development stage focuses on integration testing with Supabase, including multi-user access, database permissions, Storage permissions, and end-to-end flows.

## Running the Project

Clone the repository:

```bash
git clone https://github.com/Shahar132/CarKeep.git
```

Enter the project:

```bash
cd CarKeep
```

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

## Local Supabase for Integration Testing

CarKeep uses Supabase Local with Docker for automated integration testing.

The integration tests run only against the local Supabase environment and do not modify the hosted CarKeep database.

```text
Unit/Widget Tests
        ↓
Fake dependencies

Integration Tests
        ↓
Local Supabase + Docker
        ↓
PostgreSQL + Auth + Storage + RLS
```

### Requirements

- Docker Desktop
- Flutter
- Android SDK / ADB
- Node.js
- Supabase CLI
- Connected Android device with USB debugging enabled

### 1. Start Docker Desktop

Make sure Docker Desktop is running before starting Supabase Local.

### 2. Start Supabase Local

From the project root:

```bash
npx supabase start
```

To verify that the local environment is running:

```bash
npx supabase status
```

The local API normally runs at:

```text
http://127.0.0.1:54321
```

### 3. Connect a Physical Android Device to Supabase Local

When running the integration tests on a physical Android device, forward the local Supabase port through ADB:

```bash
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:54321 tcp:54321
```

Verify the forwarding:

```bash
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse --list
```

Expected output should include:

```text
tcp:54321 tcp:54321
```

### 4. Start the Local Edge Function

The account integration tests use the `delete-account` Edge Function.

Open Terminal 1 and run:

```bash
npx supabase functions serve delete-account
```

Keep this terminal running while the integration tests are executing.

### 5. Run the Integration Tests

Open Terminal 2.

Get the local Supabase Publishable Key from:

```bash
npx supabase status
```

Then run the complete integration test suite:

```bash
flutter test integration_test -d <ANDROID_DEVICE_ID> --dart-define=SUPABASE_TEST_ANON_KEY=<LOCAL_PUBLISHABLE_KEY>
```

Example device IDs can be found with:

```bash
flutter devices
```

The test configuration prevents the integration suite from running against a non-local Supabase URL.

### Terminal Setup

During the tests, the recommended setup is:

```text
Terminal 1
└── npx supabase functions serve delete-account

Terminal 2
└── flutter test integration_test ...
```

Supabase Local itself continues running through Docker in the background.

### Reset the Local Test Database

To completely reset the local database and reapply all migrations:

```bash
npx supabase db reset
```

This affects only Supabase Local. It does not delete or modify data in the hosted CarKeep database.

### Stop the Test Environment

First stop the Edge Function in Terminal 1 with:

```text
Ctrl + C
```

Then stop Supabase Local:

```bash
npx supabase stop
```

Docker Desktop can then be closed if it is no longer needed.

### Starting Again Later

The normal order for a new integration-testing session is:

```text
1. Start Docker Desktop
2. npx supabase start
3. Connect the Android device
4. Configure adb reverse for port 54321
5. Terminal 1: serve delete-account
6. Terminal 2: run the integration tests
7. Ctrl+C to stop the Edge Function
8. npx supabase stop when finished
```

> Never use production secret keys or service-role keys in the integration test command. Use only the Publishable Key generated by Supabase Local.

## Platforms

CarKeep is built with Flutter and targets:

- Android
- iOS
- Web

## Author

Developed by Shahar Eliyahu