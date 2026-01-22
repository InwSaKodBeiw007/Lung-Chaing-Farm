# Lung Chaing Farm

This is the frontend Flutter application for the Lung Chaing Farm marketplace. It allows villagers to sell their farm produce and provides different experiences for visitors, buyers (users), and sellers (villagers).

## Features

*   **Role-Based Access Control:**
    *   **Visitors:** Can browse all available products.
    *   **Users (Buyers):** Can register, log in, and view products. (Purchase functionality is planned).
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
