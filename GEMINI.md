# Lung Chaing Farm - Project Overview

This document provides a comprehensive overview of the "Lung Chaing Farm" application, a full-stack marketplace designed for villagers to sell their farm produce.

The application has evolved into a multi-user platform with distinct roles, secure authentication, advanced product management, and now includes robust low-stock monitoring and sales transaction history features. It features a Flutter-based frontend and a Node.js backend with an SQLite database.

## Architecture

The application follows a client-server architecture with a clear separation of concerns.

### Frontend (Flutter)

*   **Platform:** Developed using Flutter, enabling deployment to web, Android, and other platforms.
*   **State Management:** Utilizes the `provider` package for robust and scalable state management, primarily for handling global authentication state (`AuthProvider`) and low-stock product state (`LowStockProvider`).
*   **Structure:** Organized into a modular, feature-based structure with distinct directories for models, providers, services, screens for each user role (Visitor, User, Villager), and shared widgets.
*   **Key Packages:**
    *   `http`: For all API communication with the backend.
    *   `provider`: For state management.
    *   `shared_preferences`: For persisting the user's authentication token locally.
    *   `audioplayers`: For UI sound effects.
    *   `badges`: For displaying numerical badges (e.g., low stock count).
    *   `intl`: For internationalization and date formatting.

### Backend (Node.js with Express)

*   **Framework:** An API server built with Node.js and the Express framework.
*   **Authentication:** Implements a secure, token-based authentication system using **JSON Web Tokens (JWT)**. Passwords are never stored directly; instead, they are hashed using the **`bcryptjs`** library.
*   **Authorization:** API endpoints are protected using custom middleware that verifies JWTs and checks user roles and ownership, ensuring users can only access or modify data they are permitted to.
*   **Database:** Manages all application data using a local **SQLite** database (`database.db`).
*   **Image Handling:** Uses `multer` for handling multiple image uploads per product, storing them in a local `uploads` directory which is also served statically.
*   **New Features:**
    *   **Transaction Logging:** Records all sales transactions in a dedicated `transactions` table.
    *   **Low Stock Tracking:** Tracks `low_stock_since_date` in the `products` table.

### Database Schema (SQLite)

The database consists of updated tables:

*   **`users`:** Stores user information, including `id`, `email`, `password_hash`, `role` ('VILLAGER' or 'USER'), and `farm_name` for villagers.
*   **`products`:** Stores product details, including `id`, `name`, `price`, `stock`, `category`, `low_stock_threshold`, `owner_id`. Now includes `low_stock_since_date`.
*   **`product_images`:** Stores paths to product images.
*   **`transactions`:** New table storing `id`, `product_id`, `quantity_sold`, `date_of_sale`, `user_id`.

## Key Features

*   **Role-Based Access Control:**
    *   **Visitor:** Can browse all products.
    *   **User (Buyer):** Can register, log in, view products, and purchase.
    *   **Villager (Seller):** Can register, log in, has full CRUD control over their own products, and monitors low stock.
*   **Secure Authentication:** Users can register and log in. Sessions are managed securely and statelessly using JWTs.
*   **Advanced Product Management:**
    *   Villagers can manage their own product listings, including multiple images, categories, and custom low-stock thresholds.
*   **Farm Identity:** A villager's `farm_name` is displayed on their product listings.
*   **Notifications & Alerts:**
    *   **In-App Notifications:** Transient `SnackBar` messages for user feedback (success/error) and immediate alerts within the app.
    *   **Low Stock Indicator in AppBar:** A badge in the AppBar for Villagers showing the count of low-stock products.
    *   **Low Stock Products Screen:** Dedicated screen for Villagers to view low-stock products with `low_stock_since_date`.
*   **Transaction History:** Detailed sales transaction history available for each product.
*   **Product Detail Screen:** Comprehensive view for individual products, including transaction history.

## Building and Running the Project

### 1. Start the Backend Server

1.  Navigate to the `backend` directory: `cd backend`
2.  Install dependencies: `npm install`
3.  **IMPORTANT:** Configure your `.env` file in the `backend` directory with `JWT_SECRET` and your Ethereal email credentials (for testing email sending, though email alerts are currently commented out).
4.  Start the server: `node server.js`
    *   The server will run on `http://0.0.0.0:3000/`.

### 2. Run the Flutter Application

1.  **Navigate to the project root:**
    ```bash
    cd /path/to/your/lung_chaing_farm
    ```
2.  **Get dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Ensure `ApiService.baseUrl` is correct:**
    *   Open `lib/services/api_service.dart`.
    *   Verify `static const String baseUrl = 'http://localhost:3000';` (for web development).
    *   For Android emulator, use `http://10.0.2.2:3000`.
    *   For a physical device: Use your machine's network IP (e.g., `http://192.168.1.100:3000`).
4.  Run the app: `flutter run` (for a connected device) or `flutter run -d web-server` (for web).

## Project Structure (Detailed)

*   `lib/main.dart`: Main application entry point.
*   `lib/models`:
    *   `product.dart`: Defines the `Product` data model, including `lowStockSinceDate`.
    *   `user.dart`: Defines the `User` data model, including `token`.
*   `lib/providers`:
    *   `auth_provider.dart`: Manages user authentication state.
    *   `low_stock_provider.dart`: Manages the state and fetching of low-stock products.
*   `lib/screens`:
    *   `add_product_screen.dart`: Screen for adding new products.
    *   `product_list_screen.dart`: Public list of all products.
    *   `auth/`: Authentication related screens (`login_screen.dart`, `register_screen.dart`).
    *   `shared/`: Shared screens like `product_detail_screen.dart`.
    *   `user/`: User-specific screens (`user_home_screen.dart`).
    *   `villager/`: Villager-specific screens (`villager_dashboard_screen.dart`, `edit_product_screen.dart`, `low_stock_products_screen.dart`).
*   `lib/services`:
    *   `api_exception.dart`: Custom exception for API errors.
    *   `api_service.dart`: Centralized API communication, including new methods for low-stock products and transactions.
    *   `audio_service.dart`: Handles UI sound effects.
    *   `notification_service.dart`: Manages in-app notifications (SnackBars).
*   `lib/widgets`:
    *   `product_card.dart`: Reusable widget for displaying product information.
    *   `product_transaction_history.dart`: New widget for displaying a product's transaction history.
    *   `shared/`: Shared widgets like `image_gallery_swiper.dart`.
*   `test/`: Unit and widget tests.
    *   `providers/low_stock_provider_test.dart`: Tests for `LowStockProvider`.
    *   `widgets/product_transaction_history_test.dart`: Tests for `ProductTransactionHistory`.

## Development Conventions

*   **State Management:** App-wide state is managed via `ChangeNotifier` and `Provider`.
*   **API Service:** API communication is centralized in the `ApiService` singleton, managing authentication tokens.
*   **Modularity:** Code is organized by feature and/or layer to improve scalability and maintainability.
*   **Error Handling:** Custom `ApiException` and `NotificationService` for consistent, user-friendly error reporting. `try-catch` blocks are used for all risky operations.
*   **Audio Feedback:** `AudioService` provides consistent click sounds on interactive elements.
*   **Null Safety:** Strictly adheres to Dart's null safety features.
*   **Formatting:** `dart format` is used for consistent code style.
*   **Linting:** `flutter_lints` is used for code quality.
