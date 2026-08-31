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

## Platforms

CarKeep is built with Flutter and targets:

- Android
- iOS
- Web

## Author

Developed by Shahar Eliyahu