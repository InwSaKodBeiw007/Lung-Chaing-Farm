# Lung Chaing Farm: Project Overview by Gemini

This document provides a comprehensive overview of the "Lung Chaing Farm" application, detailing its purpose, architecture, implementation specifics, and file organization.

## 1. Project Purpose

The "Lung Chaing Farm" is a Flutter-based marketplace application designed to connect villagers (sellers) with users (buyers). It provides a platform for villagers to sell their farm produce and offers distinct user experiences based on roles: Visitors, Users (Buyers), and Villagers (Sellers).

## 2. Core Features Implemented

*   **One-Page Marketplace UI:** The application now features a central `OnePageMarketplaceScreen` that serves as the primary interface for browsing and purchasing, integrating seamlessly for both authenticated and unauthenticated users.
*   **Hero Section:** A prominent and visually engaging `HeroSection` has been added to the `OnePageMarketplaceScreen`, providing a dynamic introduction and call to action for products.
*   **Categorized Product Sections:** Products are neatly organized into distinct `ProductListSection` widgets by category (e.g., "Fresh Vegetables", "Delicious Fruits"), enhancing user experience and product discoverability.
*   **Quick Buy Modal:** Authenticated users (Buyers and Villagers acting as buyers) can now tap on any `ProductCard` to initiate a quick purchase through a "Quick Buy Modal," allowing for quantity selection and immediate transaction.
*   **Visitor Purchase Redirection:** Unauthenticated visitors attempting to purchase a product are now gracefully redirected to the registration/login page, encouraging account creation and engagement.
*   **Audio Feedback on Interaction:** User interactions, specifically tapping on `ProductCard`s, are now accompanied by a `click.mp3` sound effect, improving the tactile feedback and overall user experience.
*   **Role-Based Access Control:**
    *   **Visitors:** Can browse available products. Sales summary is not available for visitors; they are prompted to log in or register when attempting to buy.
    *   **Users (Buyers):** Can register, log in, view products, utilize the Quick Buy Modal, and see a total sales summary for each product.
    *   **Villagers (Sellers):** Can register, log in, manage their own products (add, edit, delete), receive low stock alerts, and view detailed transaction history for their products.
*   **Secure Authentication:** User registration and login powered by JWT (JSON Web Tokens) with hashed passwords, ensuring secure access. The login API now returns a token and a minimal user object (`{ farm_name: user.farm_name }`). The client-side application now explicitly decodes the JWT using the `jwt_decoder` package to retrieve the user's `id` and `role` for its logic and UI, which adds a layer of client-side complexity but reduces redundancy in the initial API response.
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
*   **Audio Feedback:** Now occurs on `ProductCard` taps and refresh button clicks.
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
*   `lib/models`: Dart classes representing data structures (e.g., `Product`, `User` - now includes `id`, `role`, and `token` fields, with `id` and `role` being nullable to accommodate JWT decoding).
*   `lib/providers`: `ChangeNotifierProvider` implementations for state management (e.g., `AuthProvider` - now manages the JWT-decoded `User` object for application-wide access and state, `LowStockProvider`).
*   `lib/screens`: UI screens, categorized by:
    *   `auth`: `LoginScreen`, `RegisterScreen`.
    *   `shared`: `ProductDetailScreen`.
    *   `user`: (Placeholder for future user-specific screens).
    *   `villager`: `VillagerDashboardScreen`, `LowStockProductsScreen`, `EditProductScreen`.
    *   `visitor`: (Placeholder for future visitor-specific screens).
    *   `one_page_marketplace_screen.dart`: The new central marketplace screen.
*   `lib/sections`: Major UI sections that compose screens:
    *   `hero_section.dart`: Displays a prominent hero banner.
    *   `product_list_section.dart`: Displays categorized lists of products.
*   `lib/services`: Service classes for various functionalities:
    *   `api_service.dart`: Handles all communication with the backend API, including client-side JWT decoding, user object construction from decoded tokens, and token storage using `shared_preferences`.
    *   `audio_service.dart`: Manages audio playback for UI feedback.
    *   `notification_service.dart`: Provides in-app `SnackBar` notifications.
*   `lib/widgets`: Reusable UI components:
    *   `product_card.dart`: Displays individual product information.
    *   `product_transaction_history.dart`: Displays detailed transaction history for a product.
    *   `quick_buy_modal.dart`: The modal for quick product purchases.
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

### Phase 3: Frontend - `Product` Model and `ApiService` Updates
*   Modified `lib/models/product.dart` to include a `String category` field, and handled it in `fromJson`/`toJson`.
*   Modified `lib/services/api_service.dart`'s `getProducts` to accept an optional `String? category` parameter.
*   Created unit tests for the `Product` model and `ApiService` for category handling.
*   Ensured code quality with `dart fix --apply`, `flutter analyze`, `flutter test`, and `dart format .`.

### Phase 4: Frontend - Core UI Components (`HeroSection`, `ProductListSection`, `OnePageMarketplaceScreen`)
*   Created `lib/sections/hero_section.dart` with hero banner and call to action.
*   Created `lib/sections/product_list_section.dart` for categorized product display.
*   Created `lib/screens/one_page_marketplace_screen.dart` to orchestrate `HeroSection` and `ProductListSection`s.
*   Implemented username display for authenticated `USER` roles in the AppBar.
*   Widget tests for these components were attempted but temporarily disabled due to persistent `mockito`-related issues.
*   Ensured code quality with `dart fix --apply`, `flutter analyze`, `flutter test`, and `dart format .`.

### Phase 5: Frontend - `ProductCard` Enhancements and Interactions
*   Confirmed `ProductCard` already displays `category` and price with "/kg".
*   Implemented tap interaction on `ProductCard` to play `click.mp3` using `AudioService`.
*   Created `lib/widgets/quick_buy_modal.dart` for quick product purchases.
*   Modified `lib/widgets/product_card.dart` to change `onSell` callback signature and update "Buy" button logic to show `QuickBuyModal` or redirect visitors.
*   Modified `lib/sections/product_list_section.dart` to show `QuickBuyModal` via the `onSell` callback.
*   Addressed `AudioService.instance` call error and `onSell` signature mismatches in `product_card.dart`, `product_list_screen.dart`, and `villager_dashboard_screen.dart`.
*   Ensured code quality with `dart fix --apply`, `flutter analyze`, `flutter test`, and `dart format .`.

### Phase 6: Frontend - Routing and Integration
*   Modified `lib/main.dart` to replace `ProductListScreen` with `OnePageMarketplaceScreen` as the default for unauthenticated users and `USER` role.
*   Ensured proper passing of `ApiService` or other dependencies to `OnePageMarketplaceScreen` (no explicit passing needed as `ApiService` is a singleton).
*   Corrected missing `QuickBuyModal` import in `lib/sections/product_list_section.dart`.
*   Integration tests for routing logic were temporarily skipped.
*   Ensured code quality with `dart fix --apply`, `flutter analyze`, `flutter test`, and `dart format .`.

### Phase 7: Finalization and Review
*   Addressed numerous bugs: `String?` type mismatches, `LateInitializationError`, `TypeError` for image URLs.
*   Refined sound logic: Standardized sound playback to *only* occur on refresh button clicks, removing unintended triggers.
*   UI adjustments: Removed/restored "Add Product" button as requested.
*   Code cleanup: Removed `debugPrint` statements and unused imports.
*   Documentation updates: `README.md` and `GEMINI.md` created/updated to reflect client-side JWT decoding and new user management.
*   Implemented reusable `RefreshButton` widget.
*   Implemented role-based display of sales summary on `ProductDetailScreen`.

This comprehensive overview should serve as a valuable resource for understanding, maintaining, and further developing the Lung Chaing Farm application.