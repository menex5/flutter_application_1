Fisiohub

A cross-platform mobile app built with Flutter to help physiotherapists organize their appointments and manage their clients in one place.

Overview

Physio Agenda was designed to make the daily routine of a physiotherapist simpler. Instead of paper notebooks and scattered messages, the app brings together:

A calendar-based agenda to schedule and review appointments.
A client list where each client's information can be registered and viewed.
Quick contact options, photo attachments and printable/exportable documents.

All data is stored locally on the device, so the app works without an internet connection.

Features
Appointment scheduling with an interactive monthly calendar.
Client registration and viewing (create, list and consult client records).
Photo support – attach a picture to a client's profile.
Quick contact – open phone calls or messaging apps directly from a client's profile.
PDF generation and printing – export or print client/agenda information.
Offline storage using a local SQLite database.
Tech Stack
Purpose	Package
Framework	Flutter (Dart SDK ^3.13.5)
Local database	sqflite, path
Calendar / agenda	table_calendar
Date formatting	intl
Client photos	image_picker
Calls / links	url_launcher
Floating action menu	flutter_speed_dial
PDF export and printing	pdf, printing
Getting Started
Prerequisites

Before running the project, make sure you have:

Flutter SDK installed (with Dart SDK ^3.13.5 or newer)
Git
An editor such as VS Code or Android Studio
One of the following to run the app:
An Android/iOS emulator or simulator, or
A physical device with USB debugging enabled, or
Google Chrome (to run it on the web)

Check that your environment is ready:

bash
flutter doctor
Installation
Clone the repository
bash
   git clone https://github.com/menex5/flutter_application_1.git
   cd flutter_application_1
Install the dependencies
bash
   flutter pub get
Running the app
Start an emulator or connect a device, then list the available devices:
bash
   flutter devices
Run the app
bash
   flutter run

To choose a specific device:

bash
   flutter run -d <device_id>

Examples:

bash
   flutter run -d chrome     # run in the browser
   flutter run -d windows    # run as a Windows desktop app

In VS Code you can also just press F5 (the project already includes a .vscode configuration).

Note: since the app relies on a local SQLite database (sqflite), the best experience is on Android or iOS. Desktop and web support for this package may require additional setup.

Build a release version (optional)
bash
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle
flutter build ios          # iOS (requires macOS and Xcode)
How to Use
Open the app – you will land on the main screen.
Register a client – add a new client with their information (and optionally a photo).
View your clients – browse the client list and tap a client to see their details.
Schedule an appointment – open the agenda, pick a day on the calendar and create a new appointment for a client.
Review your day – select any date on the calendar to see the appointments scheduled for it.
Contact or export – use the quick actions to call/message a client or to generate a PDF.
Project Structure
flutter_application_1/
- lib/            # Application source code (Dart)
- test/           # Automated tests
- android/        # Android platform files
─ ios/            # iOS platform files
─ web/            # Web platform files
─ windows/        # Windows platform files
─ linux/          # Linux platform files
─ macos/          # macOS platform files
─ pubspec.yaml    # Project dependencies and metadata
Running the Tests
bash
flutter test
Roadmap
 Appointment reminders / notifications
 Cloud backup and sync between devices
 Treatment history and session notes per client
 Dashboard with statistics
Contributing

Contributions are welcome!

Fork the project
Create your feature branch (git checkout -b feature/amazing-feature)
Commit your changes (git commit -m "Add amazing feature")
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request
License

This project does not have a license yet.

Author

Developed by Diego Ongaratto.
