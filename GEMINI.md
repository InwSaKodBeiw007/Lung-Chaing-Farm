# Lung Chaing Farm - Project Overview (Enhanced)

This document provides a comprehensive overview of the "Lung Chaing Farm" application, a full-stack marketplace designed for villagers to sell their farm produce.

The application has been enhanced from a simple product showcase into a multi-user platform with distinct roles, secure authentication, and advanced product management features. It features a Flutter-based frontend and a Node.js backend.

## Architecture

The application follows a client-server architecture with a clear separation of concerns.

### Frontend (Flutter)

*   **Platform:** Developed using Flutter, enabling deployment to web, Android, and other platforms.
*   **State Management:** Utilizes the `provider` package for robust and scalable state management, primarily for handling the global authentication state.
*   **Structure:** Organized into a modular, feature-based structure with distinct directories for models, providers, services, and screens for each user role (Visitor, User, Villager).
*   **Key Packages:**
    *   `http`: For all API communication with the backend.
    *   `provider`: For state management.
    *   `shared_preferences`: For persisting the user's authentication token locally.
    *   `audioplayers`: For UI sound effects.

### Backend (Node.js with Express)

*   **Framework:** An API server built with Node.js and the Express framework.
*   **Authentication:** Implements a secure, token-based authentication system using **JSON Web Tokens (JWT)**. Passwords are never stored directly; instead, they are hashed using the **`bcryptjs`** library.
*   **Authorization:** API endpoints are protected using custom middleware that verifies JWTs and checks user roles and ownership, ensuring users can only access or modify data they are permitted to.
*   **Database:** Manages all application data using a local **SQLite** database (`database.db`).
*   **Image Handling:** Uses `multer` for handling multiple image uploads per product, storing them in a local `uploads` directory which is also served statically.

### Database Schema (SQLite)

The database consists of three main tables:

*   **`users`:** Stores user information, including `email`, a hashed password, `role` ('VILLAGER' or 'USER'), and `farm_name` for villagers.
*   **`products`:** Stores product details, including `name`, `price`, `stock`, `category`, and a `low_stock_threshold`. It is linked to a user via an `owner_id`.
*   **`product_images`:** Stores paths to product images, allowing for a one-to-many relationship with the `products` table.

## Key Features

*   **Role-Based Access Control:**
    *   **Visitor:** Can browse all products.
    *   **User (Buyer):** Can register, log in, and perform purchase actions.
    *   **Villager (Seller):** Can register, log in, and has full CRUD (Create, Read, Update, Delete) control over their own products.
*   **Secure Authentication:** Users can register and log in. Sessions are managed securely and statelessly using JWTs.
*   **Advanced Product Management:**
    *   Villagers can manage their own product listings.
    *   Products can have multiple images.
    *   Products are categorized ("Sweet", "Sour").
    *   Villagers can set a custom low-stock alert threshold for each product.
*   **Farm Identity:** A villager's `farm_name` is displayed on their product listings.
*   **Notifications & Alerts:**
    *   **In-App Notifications:** Transient `SnackBar` messages for user feedback (success/error) and immediate alerts within the app.
    *   **Low Stock Overview (for Villagers):** A dedicated section in the villager dashboard that lists all products currently below their defined low stock threshold, for proactive management.
    *   *(Email notifications for low stock are currently commented out in the backend.)*

## Building and Running the Project

### 1. Start the Backend Server

1.  Navigate to the `backend` directory: `cd backend`
2.  Install dependencies: `npm install`
3.  **IMPORTANT:** Configure your `.env` file in the `backend` directory with `JWT_SECRET` and your Ethereal email credentials (for testing email sending, though email alerts are currently commented out).
4.  Start the server: `node server.js`
    *   The server will run on `http://0.0.0.0:3000/`.

### 2. Run the Flutter Application

1.  Navigate to the project root directory.
2.  Get dependencies: `flutter pub get`
3.  **IMPORTANT:** Before running, ensure the `baseUrl` in `lib/services/api_service.dart` points to your backend's IP address.
    *   For Android Emulator on the same machine: `http://10.0.2.2:3000`
    *   For Web on the same machine: `http://localhost:3000`
    *   For a physical device: Use your computer's network IP (e.g., `http://192.168.1.100:3000`).
4.  Run the app: `flutter run` (for a connected device) or `flutter run -d web-server` (for web).

## Development Conventions

*   **State Management:** App-wide state (like authentication) is managed via `ChangeNotifier` and `Provider`.
*   **API Service:** API communication is centralized in the `ApiService` singleton, which manages the inclusion of the authentication token in request headers.
*   **Modularity:** The code is organized by feature and/or layer (`models`, `providers`, `screens`) to improve scalability and maintainability.
*   **Error Handling:** Custom `ApiException` and `NotificationService` for consistent, user-friendly error reporting.
*   **Audio Feedback:** `AudioService` provides consistent click sounds on interactive elements.
