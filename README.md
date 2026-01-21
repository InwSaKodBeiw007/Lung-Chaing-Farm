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
*   **Low Stock Overview (for Villagers):** A dedicated section in the villager dashboard showing all products below their low stock threshold.

## Getting Started

### 1. Backend Setup

Ensure the Node.js backend server is running. Refer to the `backend/README.md` (or the `GEMINI.md` in the root for details) for setup instructions, including installing dependencies and starting the server.

**Important:** Remember to configure your `.env` file in the `backend` directory with your `JWT_SECRET` and Ethereal email credentials for notifications.

### 2. Frontend Setup

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
    *   For a physical device, use your machine's network IP (e.g., `http://192.168.1.X:3000`).

### 3. Running the Application

*   **For Web:**
    ```bash
    flutter run -d web-server
    ```
*   **For Android:**
    ```bash
    flutter run
    ```
    (Ensure an emulator is running or a device is connected).

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