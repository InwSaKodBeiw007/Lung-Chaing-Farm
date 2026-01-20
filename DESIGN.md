# Lung Chaing Farm - Marketplace Enhancement Design

## 1. Overview

This document outlines the design for enhancing the existing `lung_chaing_farm` application. The goal is to transform the current simple product viewer into a multi-faceted marketplace. This involves introducing distinct user roles, implementing a robust authentication system, expanding product details to include multiple images and custom alerts, and adding a notification system for low-stock alerts.

The project will continue to use Flutter for the frontend and Node.js with Express and SQLite for the backend, extending the current architecture to support the new features.

## 2. Analysis of Goal and Problem

### Current State (The Problem)

*   **Single User Type:** The application does not differentiate between users. Anyone can see the products, but there is no concept of ownership, selling, or buying.
*   **No Authentication:** There is no login or registration system, posing a significant security and data integrity issue for a marketplace.
*   **Limited Product Management:** Products are managed through a simple, open interface. There is no way to tie a product to a specific seller (villager).
*   **Basic Product Details:** Products only have a single image, a name, price, and stock. It lacks categorization and flexibility for sellers.
*   **Manual Stock Alerts:** The low-stock warning is purely a visual indicator on the frontend. There is no automated notification system to proactively alert the seller.

### Desired State (The Goal)

*   **Role-Based Access Control:** Implement three distinct user roles:
    *   **Visitor:** Unauthenticated users with read-only access to products.
    *   **User (Buyer):** Authenticated users who can view and "purchase" products. They must provide details like address and contact information.
    *   **Villager (Seller/Admin):** Authenticated users with full CRUD (Create, Read, Update, Delete) control over their own products.
*   **Secure Authentication:** A complete authentication system (registration and login) to manage user sessions and protect routes.
*   **Advanced Product Management:**
    *   Products are owned by Villagers.
    *   Products support multiple images in a swipe-able gallery.
    *   Products can be categorized as "Sweet" or "Sour".
    *   Villagers can set a custom low-stock alert threshold for each of their products.
*   **Automated Notifications:** When a product's stock level falls below its custom threshold, the owning Villager will receive both an in-app notification and an email.

## 3. Alternatives Considered

### Backend Technology

*   **Alternative:** Use a Backend-as-a-Service (BaaS) like Firebase or Supabase.
    *   *Pros:* Faster development for authentication, database, and file storage.
    *   *Cons:* Less granular control, potential for vendor lock-in, and introduces a completely new technology stack.
*   **Decision:** **Continue with the existing Node.js/Express/SQLite stack.** This leverages the current codebase, offers maximum control, and maintains project consistency. We will implement authentication and email features using well-established Node.js libraries.

### Flutter State Management

*   **Alternative:** The current implementation relies heavily on `setState` and `FutureBuilder`, which is insufficient for managing a global authentication state. A more robust solution is needed. We could use Provider, Riverpod, BLoC, or others.
*   **Decision:** **Introduce the `provider` package.** It is a recommended, straightforward solution for dependency injection and state management that integrates well with `ChangeNotifier`. It is powerful enough for our needs (managing authentication state) without adding excessive boilerplate.

## 4. Detailed Design

### 4.1. Backend (Node.js)

#### 4.1.1. Database Schema (`database.db`)

We will add two new tables (`users`, `product_images`) and modify the existing `products` table.

```mermaid
erDiagram
    users {
        INTEGER id PK
        TEXT email UNIQUE
        TEXT password_hash
        TEXT role "('VILLAGER', 'USER')"
        TEXT farm_name "Nullable, for Villagers"
        TEXT address
        TEXT contact_info
    }

    products {
        INTEGER id PK
        INTEGER owner_id FK
        TEXT name
        REAL price
        REAL stock
        TEXT category "('Sweet', 'Sour')"
        REAL low_stock_threshold "default 7"
    }

    product_images {
        INTEGER id PK
        INTEGER product_id FK
        TEXT image_path
    }

    users ||--o{ products : "owns"
    products ||--o{ product_images : "has"

```

*   **`users` table:** Will store authentication and role information. A new `farm_name` field (nullable) will be added to store the farm name for users with the `VILLAGER` role.
*   **`products` table modification:**
    *   `owner_id`: Foreign key linking to the `users` table to establish ownership.
    *   `category`: Stores the product category.
    *   `low_stock_threshold`: Stores the seller-defined alert level.
    *   The old `imagePath` column will be removed in favor of the new `product_images` table.
*   **`product_images` table:** A one-to-many relationship with `products` to allow for multiple images.

#### 4.1.2. API Endpoints & Authentication

Authentication will be handled using **JSON Web Tokens (JWT)**.

*   `POST /auth/register`: Creates a new user (Villager or User).
*   `POST /auth/login`: Authenticates a user and returns a JWT.
*   `GET /auth/me`: (Protected) Returns the profile of the currently logged-in user.

Product routes will be updated and protected based on user roles.

*   `GET /products`: Publicly accessible.
*   `GET /products/:id`: Publicly accessible.
*   `POST /products`: **Protected (Villager only)**. Allows a villager to add a new product.
*   `PUT /products/:id`: **Protected (Owner only)**. Allows a villager to update their own product.
*   `DELETE /products/:id`: **Protected (Owner only)**. Allows a villager to delete their own product.
*   `POST /products/:id/sell`: **Protected (User only)**. Simulates a purchase by decrementing stock.

#### 4.1.3. Email Notification Service

We will use the `Nodemailer` library. A service will be created and called after any stock update. If the new stock level is below the `low_stock_threshold`, it will dispatch an email to the product owner's email address.

### 4.2. Frontend (Flutter)

#### 4.2.1. Project Structure

The `lib` directory will be reorganized to be more modular and scalable.

```
lib/
├── models/
│   ├── product.dart
│   └── user.dart
├── providers/
│   └── auth_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── shared/
│   │   └── product_detail_screen.dart
│   ├── user/
│   │   └── user_home_screen.dart
│   ├── villager/
│   │   ├── edit_product_screen.dart
│   │   └── villager_dashboard_screen.dart
│   └── visitor/
│       └── visitor_home_screen.dart
├── services/
│   ├── api_service.dart      // Will be heavily updated
│   ├── audio_service.dart
│   └── notification_service.dart // For in-app notifications
├── widgets/
│   ├── product_card.dart     // Will be updated
│   └── shared/
│       └── image_gallery_swiper.dart
└── main.dart
```

#### 4.2.2. State Management & Routing

*   `main.dart` will be wrapped with a `ChangeNotifierProvider` for the `AuthProvider`.
*   The app will start by checking for a stored JWT.
    *   If no token exists, it will display `VisitorHomeScreen`.
    *   If a token exists, it will validate it with the backend. Based on the returned user role, it will navigate to `VillagerDashboardScreen` or `UserHomeScreen`.
*   `AuthProvider` will hold the user's token, role, and authentication status. It will notify listeners when the state changes (e.g., on login or logout), causing the UI to rebuild and show the appropriate screen.

#### 4.2.3. UI/UX Flow

1.  **Launch:** App shows `VisitorHomeScreen` (a grid of products) with "Login" and "Register" buttons.
2.  **Authentication:** Users can register (as a Villager or User) or log in via dedicated screens.
3.  **Post-Login:**
    *   **Villagers** are taken to their dashboard, showing a list of *their* products with "Edit" and "Delete" options, and a prominent "Add New Product" button.
    *   **Users** are taken to a "shopping" view, which is a more polished version of the visitor view, but with "Buy" buttons on products.
4.  **Product Creation/Editing:** Villagers will use a form that includes fields for all product details, a multi-image uploader, and the custom low-stock alert threshold.

## 5. Summary of Design

The proposed design enhances the `lung_chaing_farm` application by introducing a robust, role-based architecture. It maintains the existing technology stack (Flutter/Node.js) for consistency while introducing `provider` for scalable state management and `JWT` for security. The database schema will be expanded to support user ownership and richer product details. API endpoints will be protected, and the frontend will be restructured into modular, role-specific views. Finally, an automated notification system using Nodemailer will provide proactive alerts to sellers.

## 6. References

*   **JSON Web Token (JWT) for Node.js:** [DigitalOcean: How To Implement JSON Web Tokens (JWTs) in a Node.js App](https://www.digitalocean.com/community/tutorials/nodejs-jwt-express-mongodb) (Concepts will be adapted for SQLite).
*   **Provider for Flutter:** [Official `provider` package documentation](https://pub.dev/packages/provider).
*   **Nodemailer for Email:** [Nodemailer Official Website](https://nodemailer.com/).
*   **SQLite in Node.js:** [Official `sqlite3` package documentation](https://www.npmjs.com/package/sqlite3).
