# Lung Chaing Farm

This is the frontend Flutter application for the Lung Chaing Farm marketplace. It allows villagers to sell their farm produce and provides different experiences for visitors, buyers (users), and sellers (villagers).

## Features

*   **One-Page Marketplace Experience:** A redesigned single-page view (`OnePageMarketplaceScreen`) serves as the default for unauthenticated users and regular buyers, offering a streamlined browsing and purchasing experience.
*   **Hero Section:** A prominent `HeroSection` on the marketplace screen features a dynamic title, engaging banner image, and a clear call to action to "View Today's Products".
*   **Categorized Product Listings:** Products are intuitively organized into distinct sections (e.g., "Fresh Vegetables", "Delicious Fruits") using `ProductListSection`, enhancing product discoverability.
*   **Quick Buy Modal:** Authenticated buyers can now tap on any `ProductCard` to open a "Quick Buy Modal," enabling quick selection of desired quantity and immediate purchase confirmation.
*   **Visitor Purchase Redirection:** Unauthenticated visitors attempting to interact with purchase options on a `ProductCard` are gracefully redirected to the registration/login page, encouraging engagement.
*   **Audio Feedback on Interaction:** User interactions, specifically tapping on `ProductCard`s, are enhanced with subtle `click.mp3` audio feedback, improving responsiveness and user experience.
*   **Role-Based Access Control:**
    *   **Visitors:** Can browse all available products.
    *   **Users (Buyers):** Can register, log in, view products, and utilize the new Quick Buy Modal for purchases.
    *   **Villagers (Sellers):** Can register, log in, manage their own products (add, edit, delete), and receive low stock alerts.
*   **Secure Authentication:** User registration and login powered by JWT (JSON Web Tokens) with hashed passwords.
*   **Advanced Product Management:**
    *   Villagers can add and edit products with multiple images, categories ("Sweet", "Sour"), and custom low stock thresholds.
    *   Product cards display `farm_name` and images in a swipeable gallery.
*   **In-App Notifications:** Transient `SnackBar` messages for user feedback (success/error) and low stock alerts.
*   **Low Stock Overview (for Villagers):** A dedicated section in the villager dashboard showing all products below their low stock threshold, now accessible via an AppBar icon.
*   **Low Stock Products View:** A dedicated screen for Villagers to view all low-stock products, including their `low_stock_since_date`.
*   **Product Detail Screen:** A comprehensive screen accessible by tapping any product card, displaying full product information and its transaction history.
*   **Expandable Transaction History:** On the Product Detail Screen and within the Low Stock Products View, individual product entries now feature an expandable section to reveal sales transaction history.

## Project Structure

The project follows a modular structure:

*   `lib/models`: Data models for users and products.
*   `lib/providers`: State management using `provider` (e.g., `AuthProvider`).
*   `lib/screens`: Major UI pages, organized by feature/role (`auth`, `user`, `villager`, `shared`, `visitor`).
*   `lib/services`: Business logic, API communication (`ApiService`), audio, and notifications.
*   `lib/widgets`: Reusable UI components.

## Development

*   **State Management:** `provider` package is used for global state management.
*   **API Communication:** Handled by `ApiService`, which includes JWT for authentication.
*   **Audio Feedback:** `AudioService` provides click sounds on interactive elements.
*   **Error Handling:** Custom `ApiException` and `NotificationService` for consistent error reporting.
