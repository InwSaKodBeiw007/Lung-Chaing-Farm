# Lung Chaing Farm: Project Overview by Gemini

This document provides a comprehensive overview of the "Lung Chaing Farm" application, detailing its purpose, architecture, implementation specifics, and file organization.

## 1. Project Purpose

The "Lung Chaing Farm" is a Flutter-based marketplace application designed to connect villagers (sellers) with users (buyers). It provides a platform for villagers to sell their farm produce and offers distinct user experiences based on roles: Visitors, Users (Buyers), and Villagers (Sellers).

## 2. Core Features Implemented

*   **Role-Based Access Control:**
    *   **Visitors:** Can browse available products. Sales summary is not available for visitors; they are prompted to log in.
    *   **Users (Buyers):** Can register, log in, view products, and see a total sales summary for each product.
    *   **Villagers (Sellers):** Can register, log in, manage their own products (add, edit, delete), receive low stock alerts, and view detailed transaction history for their products.
*   **Secure Authentication:** User registration and login powered by JWT (JSON Web Tokens) with hashed passwords, ensuring secure access.
*   **Advanced Product Management:**
    *   Villagers can add and edit products with multiple images, categories ("Sweet", "Sour"), and custom low stock thresholds.
    *   Product cards display `farm_name` and images in a swipeable gallery.
*   **In-App Notifications:** Transient `SnackBar` messages provide user feedback (success/error) and deliver low stock alerts.
*   **Low Stock Monitoring (for Villagers):**
    *   A dedicated section in the villager dashboard showing all products below their low stock threshold.
    *   An AppBar icon (shop-cart) accessible to Villagers, displaying a badge with the count of currently low-stock products.
    *   A dedicated `LowStockProductsScreen` for Villagers to view all low-stock products, including their `low_stock_since_date`.
*   **Sales Transaction History:**
    *   **Product Detail Screen:** A comprehensive screen accessible by tapping any product card, displaying full product information.
    *   **Expandable Transaction History:** Villagers can view detailed sales transaction history within `ProductDetailScreen` and `LowStockProductsScreen`.
    *   **Sales Summary for Users/Visitors:** Non-Villager roles see only a "Total Units Sold" summary on the `ProductDetailScreen` (for authenticated Users) or a prompt to log in (for Visitors).
*   **Audio Feedback:** Standardized to *only* occur on refresh button clicks. All other UI interactions are silent.
*   **Reusable Components:** Extracted common refresh functionality into a `RefreshButton` widget for better modularity.

## 3. Architecture and Technologies

The application follows a client-server architecture:

*   **Frontend:** Developed using **Flutter** (Dart language), targeting mobile and web platforms.
    *   **State Management:** `provider` package.
    *   **Routing:** Standard Flutter `Navigator`.
    *   **UI Components:** Material Design widgets.
*   **Backend:** Developed using **Node.js** with **Express.js**.
    *   **Database:** **SQLite** (`sqlite3` package).
    *   **Authentication:** JWT.
    *   **Email Service:** NodeMailer for registration emails.

## 4. Database Schema

The SQLite database includes `users`, `products`, `product_images`, and `transactions` tables.

### ER Diagram (from MODIFICATION_DESIGN.md)

```mermaid
erDiagram
    users ||--o{ products : "owns"
    products ||--o{ product_images : "has"
    products ||--o{ transactions : "has"

    users {
        INTEGER id PK
        TEXT email
        TEXT password_hash
        TEXT role
        TEXT farm_name
    }

    products {
        INTEGER id PK
        TEXT name
        REAL price
        INTEGER stock
        TEXT category
        INTEGER low_stock_threshold
        INTEGER owner_id FK "users.id"
        INTEGER low_stock_since_date NULL "Unix timestamp"
    }

    product_images {
        INTEGER id PK
        INTEGER product_id FK "products.id"
        TEXT image_path
    }

    transactions {
        INTEGER id PK
        INTEGER product_id FK "products.id"
        INTEGER quantity_sold
        INTEGER date_of_sale "Unix timestamp"
        INTEGER user_id FK "users.id"
    }
```

## 5. Backend API Endpoints

Key API endpoints include:

*   **`POST /auth/register`**: User registration.
*   **`POST /auth/login`**: User login.
*   **`GET /products`**: Retrieve all products.
*   **`GET /products/:id`**: Retrieve a single product.
*   **`POST /products`**: Add a new product (Villager only).
*   **`PUT /products/:id`**: Update a product (Villager only).
*   **`DELETE /products/:id`**: Delete a product (Villager only).
*   **`POST /api/products/:productId/purchase`**: Handle product purchase, decrement stock, and record transaction.
*   **`GET /api/villager/low-stock-products`**: Retrieve low-stock products for the authenticated Villager.
*   **`GET /api/products/:productId/transactions`**: Retrieve sales transaction history for a specific product.

## 6. Frontend File Organization

The Flutter frontend (`lib` directory) is organized as follows:

*   `main.dart`: Application entry point, `AuthWrapper` for role-based routing.
*   `lib/models`: Dart classes representing data structures (e.g., `Product`, `User`).
*   `lib/providers`: `ChangeNotifierProvider` implementations for state management (e.g., `AuthProvider`, `LowStockProvider`).
*   `lib/screens`: UI screens, categorized by:
    *   `auth`: `LoginScreen`, `RegisterScreen`.
    *   `shared`: `ProductDetailScreen`.
    *   `user`: (Placeholder for future user-specific screens).
    *   `villager`: `VillagerDashboardScreen`, `LowStockProductsScreen`, `EditProductScreen`.
    *   `visitor`: (Placeholder for future visitor-specific screens).
*   `lib/services`: Service classes for various functionalities:
    *   `api_service.dart`: Handles all communication with the backend API.
    *   `audio_service.dart`: Manages audio playback for UI feedback.
    *   `notification_service.dart`: Provides in-app `SnackBar` notifications.
*   `lib/widgets`: Reusable UI components:
    *   `product_card.dart`: Displays individual product information.
    *   `product_transaction_history.dart`: Displays detailed transaction history for a product.
    *   `shared/image_gallery_swiper.dart`: Swipeable image gallery for products.
    *   `refresh_button.dart`: Reusable button for refreshing content.

## 7. Development Workflow

The project utilizes standard Flutter and Node.js development practices:

*   **Code Generation:** `build_runner` for `json_serializable` (not currently used but standard for models).
*   **Linting & Formatting:** `flutter_lints` and `dart format` ensure code quality and consistency.
*   **Testing:** Unit and widget tests are used for critical components.

## 8. Development History (from MODIFICATION_IMPLEMENTATION.md)

The project enhancements were conducted in several phases:

### Phase 0: Initial Setup and Verification
*   Created design documentation (`MODIFICATION_DESIGN.md`).
*   Confirmed initial project state.

### Phase 1: Database and Backend Foundations
*   Implemented `products` table modifications (`low_stock_since_date`).
*   Created `transactions` table.
*   Backend tests for schema were added.

### Phase 2: Backend API Endpoints and Logic
*   Implemented `POST /api/products/:productId/purchase` (purchase, decrement stock, record transaction).
*   Implemented `GET /api/villager/low-stock-products` (retrieve low-stock products for Villager).
*   Implemented `GET /api/products/:productId/transactions` (retrieve sales transaction history).

### Phase 3: Frontend - Low Stock Indicator and Routing
*   Integrated `shop-cart.png` icon.
*   Created `LowStockProvider` for low-stock product state management.
*   Implemented AppBar low-stock indicator with `Badge`.
*   Created `LowStockProductsScreen`.

### Phase 4: Frontend - Transaction History Display
*   Created `ProductTransactionHistory` reusable widget.
*   Integrated `ProductTransactionHistory` into `LowStockProductsScreen` and `ProductDetailScreen`.
*   Modified `ProductCard` for navigation to `ProductDetailScreen`.

### Phase 5: Finalization and Review
*   Addressed numerous bugs: `String?` type mismatches, `LateInitializationError`, `TypeError` for image URLs.
*   Refined sound logic: Standardized sound playback to *only* occur on refresh button clicks, removing unintended triggers.
*   UI adjustments: Removed/restored "Add Product" button as requested.
*   Code cleanup: Removed `debugPrint` statements and unused imports.
*   Documentation updates: `README.md` and `GEMINI.md` created/updated.
*   Implemented reusable `RefreshButton` widget.
*   Implemented role-based display of sales summary on `ProductDetailScreen`.

This comprehensive overview should serve as a valuable resource for understanding, maintaining, and further developing the Lung Chaing Farm application.