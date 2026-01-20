# Lung Chaing Farm Project Overview

This project is a full-stack application named "Lung Chaing Farm," designed to facilitate a village marketplace for farm produce. It features a Flutter-based frontend that can run on the web and Android, and a Node.js backend that manages product data and image storage using SQLite.

## Architecture

The application follows a client-server architecture:

*   **Frontend (Flutter):**
    *   Developed using Flutter, enabling deployment to web and Android platforms.
    *   Provides user interfaces for viewing products, adding new products, and managing existing ones.
    *   Uses the `http` package for API communication and `audioplayers` for sound effects.
    *   Handles image selection and preview.

*   **Backend (Node.js with Express):**
    *   An API server built with Node.js and the Express framework.
    *   Manages product data (name, price, stock, imagePath) stored in a SQLite database.
    *   Uses `multer` for handling image uploads, storing them in a local `uploads` directory.
    *   Serves uploaded images statically to the frontend.
    *   Configured with CORS to allow cross-origin requests from the Flutter frontend.
    *   Runs on `0.0.0.0` to ensure accessibility from different devices on the network.

*   **Database (SQLite):**
    *   A local SQLite database (`database.db`) managed by the Node.js backend.
    *   Contains a `products` table. (Note: A `sales` table was mentioned in the original prompt but is not yet implemented.)

## Key Features

*   **Product Listing:** Displays available farm products in a grid view.
*   **Product Management:** Allows users to add new products with an image, update product stock (e.g., when a unit is sold), and delete products.
*   **Image Handling:** Supports uploading product images to the backend and displaying them in the frontend.
*   **Stock Alert:** Visually indicates products with low stock (less than 5 units).
*   **Click Sounds:** Provides auditory feedback on key user interactions (refresh, add product, sell, delete, pick image).

## Building and Running the Project

### Prerequisites

*   Node.js and npm installed.
*   Flutter SDK installed and configured.
*   A `click.mp3` sound file for assets (see Assets section below).

### 1. Start the Backend Server

The backend server must be running for the Flutter application to function correctly.

1.  Navigate to the `backend` directory:
    ```bash
    cd backend
    ```
2.  Install Node.js dependencies (if not already done):
    ```bash
    npm install
    ```
3.  Start the server. Keep this terminal open:
    ```bash
    node server.js
    ```
    You should see output similar to:
    ```
    Connected to the SQLite database.
    Products table is ready.
    Server running at http://0.0.0.0:3000/
    ```

### 2. Configure Flutter Assets

1.  Ensure you have a sound file named `click.mp3`.
2.  Create an `assets/sounds` directory at the root of your Flutter project (e.g., `lung_chaing_farm/assets/sounds`).
3.  Place your `click.mp3` file inside the `assets/sounds` directory.

### 3. Run the Flutter Application

#### For Web

1.  Ensure you are in the root directory of the Flutter project (`lung_chaing_farm`).
2.  Get Flutter package dependencies (if not already done, or after modifying `pubspec.yaml`):
    ```bash
    flutter pub get
    ```
3.  Run the application on a web server:
    ```bash
    flutter run -d web-server
    ```
    This command will provide a URL (e.g., `http://localhost:XXXX/`) which you can open in your web browser.

#### For Android

1.  Ensure an Android emulator is running or a physical device is connected.
2.  Ensure you are in the root directory of the Flutter project (`lung_chaing_farm`).
3.  Get Flutter package dependencies (if not already done, or after modifying `pubspec.yaml`):
    ```bash
    flutter pub get
    ```
4.  Run the application on the Android device:
    ```bash
    flutter run
    ```
    The application will be installed and launched on your emulator/device.

### Important Configuration Notes

*   **Backend URL (`ApiService.baseUrl`):**
    *   In `lib/services/api_service.dart`, the `baseUrl` is currently `http://localhost:3000`.
    *   For Android emulators, you might need to change `localhost` to `http://10.0.2.2:3000` (a special IP for emulators to access the host machine's localhost).
    *   For physical devices or deployment to a cloud server, you *must* update this to the actual IP address or domain of your Node.js backend.
*   **Android Permissions (`AndroidManifest.xml`):**
    *   The `android/app/src/main/AndroidManifest.xml` file has been updated to include `<uses-permission android:name="android.permission.INTERNET"/>` and `android:usesCleartextTraffic="true"` for network access.

## Development Conventions

*   **Code Structure:**
    *   Flutter frontend adheres to a modular structure with `lib/screens` for major UI pages, `lib/widgets` for reusable UI components, and `lib/services` for business logic and API communication.
    *   Node.js backend code is located in the `backend/` directory, separated from the Flutter project.
*   **Error Handling:** Basic error handling is implemented for API calls and form validations.
*   **Platform Compatibility:** Code is written with consideration for both web and Android platforms, particularly regarding image handling and asset loading.

## Future Enhancements (from original prompt)

*   Implementation of a `sales` table in the backend database to track sales transactions.
*   More robust user authentication and authorization.
*   Deployment to a cloud environment for the Node.js backend and Flutter web app.
