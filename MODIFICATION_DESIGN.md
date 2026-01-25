# Modification Design Document: One-Page Marketplace Application

## 1. Overview

This document outlines the design for implementing a new "One-Page Marketplace Application" within the existing Flutter project, targeting web and mobile platforms. The primary goal is to create an engaging landing page for visitors and potentially regular users (buyers) to browse agricultural products. This new feature will replace the existing `ProductListScreen` as the default view for unauthenticated users, providing a richer, more interactive experience. The design covers necessary backend modifications (database schema and API) and comprehensive frontend development, adhering to a minimalist e-commerce style with specific UI elements and interactions.

## 2. Detailed Analysis of the Goal or Problem

The current application structure uses `ProductListScreen` as the default entry point for unauthenticated users. This screen is functional but lacks the dynamic, feature-rich presentation desired for a modern e-commerce marketplace. The goal is to transform this into a visually appealing and highly usable one-page experience that highlights products, categorizes them, and encourages interaction.

**Key problems addressed by this modification:**

*   **Limited User Experience for Visitors:** The current `ProductListScreen` is basic and does not effectively showcase products or provide an inviting entry point.
*   **Lack of Product Categorization:** Products are currently displayed in a flat list, without clear separation between categories like "Vegetables" and "Fruits."
*   **Static Content Presentation:** No dedicated "Hero Section" or dynamic product sections.
*   **No Quick Buy Interaction:** The user experience lacks immediate feedback and quick purchase options for product selection.
*   **Backend Support for Categorization:** The existing backend API does not support filtering products by category, which is essential for the new UI.

## 3. Alternatives Considered

### Alternative 1: Create a Separate Flutter Web Project

*   **Pros:** Complete separation of concerns, potentially simpler to develop independently.
*   **Cons:** Duplication of code (models, services), complex integration with the existing mobile app (if needed), maintaining two separate codebases.

### Alternative 2: Integrate as a New Route within the Existing `AuthWrapper`

*   **Pros:** Allows for a distinct URL/route for the one-page.
*   **Cons:** Still requires deciding when to route to it (e.g., for specific roles), adding complexity to the existing `AuthWrapper` logic if not replacing an existing screen.

**Chosen Approach:**
The chosen approach is to **replace the `ProductListScreen` with the new One-Page Marketplace application for unauthenticated users.** This integrates the new functionality seamlessly into the existing application flow without introducing unnecessary routing complexity or code duplication. It directly addresses the need for an improved landing experience for visitors. For authenticated `USER` roles, this new one-page will also serve as their primary product browsing interface, aligning with the marketplace concept.

## 4. Detailed Design for the Modification

The modification will involve significant changes across the backend and frontend.

### 4.1 Backend Modifications

**Objective:** To enable product categorization and filtering by category.

#### 4.1.1 Database Schema Modification

The `products` table in the SQLite database needs to be updated to include a `category` field.

**Before:**

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    stock INTEGER NOT NULL,
    low_stock_threshold INTEGER NOT NULL,
    owner_id INTEGER,
    low_stock_since_date INTEGER,
    FOREIGN KEY (owner_id) REFERENCES users (id)
);
```

**After:**

```sql
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    price REAL NOT NULL,
    stock INTEGER NOT NULL,
    category TEXT NOT NULL, -- New field: e.g., 'Vegetable', 'Fruit'
    low_stock_threshold INTEGER NOT NULL,
    owner_id INTEGER,
    low_stock_since_date INTEGER,
    FOREIGN KEY (owner_id) REFERENCES users (id)
);
```

**Mermaid Diagram: Updated `products` table**

```mermaid
erDiagram
    users ||--o{ products : "owns"
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
```

#### 4.1.2 API Modifications

The `GET /products` endpoint in `backend/server.js` needs to be modified to accept an optional `type` query parameter for filtering products by category.

**Current `GET /products` (Conceptual):**

```javascript
app.get('/products', (req, res) => {
    db.all('SELECT * FROM products', [], (err, rows) => {
        // ... send all products
    });
});
```

**Modified `GET /products` (Conceptual):**

```javascript
app.get('/products', (req, res) => {
    const category = req.query.category; // e.g., 'Vegetable', 'Fruit'
    let sql = 'SELECT * FROM products';
    const params = [];

    if (category) {
        sql += ' WHERE category = ?';
        params.push(category);
    }

    db.all(sql, params, (err, rows) => {
        // ... send filtered or all products
    });
});
```

### 4.2 Frontend Modifications

**Objective:** To implement the one-page marketplace UI and integrate with the modified backend.

#### 4.2.1 Core Structure and Routing

*   The existing `AuthWrapper` in `main.dart` will be updated to display the new one-page screen (`OnePageMarketplaceScreen`) when a user is not authenticated or if their role is `USER`.
*   The `ProductListScreen` will be effectively replaced by `OnePageMarketplaceScreen`.

#### 4.2.2 New UI Screens and Widgets

*   **`lib/screens/one_page_marketplace_screen.dart`**: This will be the main screen widget, orchestrating the `HeroSection` and `ProductListSection` widgets.
*   **User Profile Display (for authenticated USERs)**: When a `USER` is authenticated, their username (specifically `authProvider.user!.farm_name` as per the existing `AuthProvider`) will be displayed in the header of the `OnePageMarketplaceScreen`, serving as a simple profile indicator.
*   **`lib/sections/hero_section.dart`**:
    *   A `StatelessWidget` (or `StatefulWidget` if dynamic elements are needed beyond the initial build).
    *   Will display the farm name "KK Farm".
    *   Will include anchor links (using `ScrollablePositionedList` or similar for smooth scrolling to sections).
    *   A banner with an image and a "View Today's Products" button (which will scroll to the product sections).
*   **`lib/sections/product_list_section.dart`**:
    *   A `StatefulWidget` responsible for fetching and displaying products for a given category.
    *   Will take a `category` parameter (e.g., 'Vegetable', 'Fruit').
    *   Will use `FutureBuilder` or similar to handle asynchronous data fetching from `ApiService`.
    *   Will display products in a `GridView.builder` using the existing `ProductCard` widget.
    *   Will include a header for the category (e.g., "ผักสด" or "ผลไม้").
*   **`lib/widgets/product_card.dart`**:
    *   Will be modified (if necessary) to display the category, price per kg, and stock alert. (Based on existing description, it already shows image, name, stock, but category and price_per_kg might need explicit handling).
    *   Interaction: On tap, it will trigger the `click.mp3` sound and open a "Quick Buy Modal" (a `showDialog` or `showModalBottomSheet` for quick purchase).

#### 4.2.3 State Management and Services

*   **`lib/services/api_service.dart`**:
    *   The `fetchProducts` method will be updated to accept an optional `category` parameter.
    *   Example signature: `Future<List<Product>> fetchProducts({String? category})`.
*   **`lib/services/audio_service.dart`**:
    *   Ensure the `playClickSound()` method is available and integrated with the product card tap.
*   **`lib/models/product.dart`**:
    *   Ensure the `Product` model includes the new `category` field.

**Mermaid Diagram: Frontend UI Flow**

```mermaid
graph TD
    A[main.dart: AuthWrapper] --> B{Authenticated?}
    B -- No --> C[OnePageMarketplaceScreen]
    B -- Yes (Role: USER) --> C
    B -- Yes (Role: VILLAGER) --> D[VillagerDashboardScreen]

    C --> E[HeroSection]
    C --> F[ProductListSection (Vegetables)]
    C --> G[ProductListSection (Fruits)]

    F --> H[ProductCard (Vegetable 1)]
    F --> I[ProductCard (Vegetable 2)]
    G --> J[ProductCard (Fruit 1)]
    G --> K[ProductCard (Fruit 2)]

    H -- Tap --> L[Play click.mp3]
    H -- Tap --> M[Show Quick Buy Modal]

    E -- "View Today's Products" button --> F
```

#### 4.2.4 Styling

*   **Color Palette**: Use `ThemeData` to establish natural color tones (white, light green, wood brown). The `ColorScheme.fromSeed` will be used with `Colors.lightGreen` as the seed, and careful selection of other colors to match the "natural" theme.
*   **Elevation**: Apply subtle elevation to `ProductCard` and other relevant UI elements to achieve the modern one-page aesthetic.
*   **Typography**: Ensure consistent and legible typography throughout the application.

## 5. Summary of the Design

This design proposes a comprehensive update to the Lung Chaing Farm application, transforming the visitor and buyer experience into a modern, interactive one-page marketplace. Key elements include:

*   Backend database and API modifications to support product categorization.
*   A new `OnePageMarketplaceScreen` in Flutter, integrating a `HeroSection` and dynamic `ProductListSection` for vegetables and fruits.
*   Enhanced `ProductCard` interactions with audio feedback and a quick buy modal.
*   Adherence to specific styling guidelines for a natural and minimalist aesthetic.
*   Integration by replacing the existing `ProductListScreen` for unauthenticated users and potentially for general users/buyers.

This approach ensures a cohesive and improved user experience, leveraging existing components where possible while introducing necessary new functionality and UI elements.

## 6. References

*   [Flutter `GridView.builder` documentation](https://api.flutter.dev/flutter/widgets/GridView/GridView.builder.html)
*   [Flutter `FutureBuilder` documentation](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html)
*   [Flutter `showDialog` (for modals)](https://api.flutter.dev/flutter/material/showDialog.html)
*   [SQLite `ALTER TABLE ADD COLUMN`](https://www.sqlite.org/lang_altertable.html)
