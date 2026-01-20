# Implementation Plan: Lung Chaing Farm Marketplace Enhancement

This document outlines the phased implementation plan for enhancing the `lung_chaing_farm` application based on the approved `DESIGN.md`.

## Journal

*This section will be updated chronologically after each phase to log actions, learnings, and any deviations from the plan.*

---

## Phase 1: Backend Foundations - Database and Authentication

**Goal:** Restructure the database and implement the core user authentication and registration system.

- [ ] **Dependency Update:** Add `jsonwebtoken` for handling JWTs and `bcryptjs` for password hashing to the `backend/package.json`.
- [ ] **Database Migration:** Update the `backend/server.js` startup script to:
    - Create the new `users` table with `farm_name`.
    - Create the new `product_images` table.
    - Modify the existing `products` table: add `owner_id`, `category`, `low_stock_threshold`, and remove the old `imagePath` column. Handle this migration gracefully to avoid data loss if run multiple times.
- [ ] **Authentication Endpoints:**
    - Implement `POST /auth/register` to create new users (both 'VILLAGER' and 'USER'), hashing passwords with `bcryptjs`.
    - Implement `POST /auth/login` to validate credentials, compare password hashes, and issue a JWT upon success.
- [ ] **Security Middleware:** Create a middleware function that can be applied to protected routes. This function will verify the `Authorization` header for a valid JWT and attach the user's data to the request object.

### Phase 1: Post-Implementation Checklist
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run `npm install` in the `backend` directory to ensure all new dependencies are installed.
- [ ] Re-read this `IMPLEMENTATION.md` file to see what, if anything, has changed in the implementation plan.
- [ ] Update the **Journal** section with learnings, surprises, or deviations. Check off completed tasks.
- [ ] Use `git diff` to verify the changes, create a suitable commit message, and present it for approval.
- [ ] **Await user approval before committing or moving to the next phase.**

---

## Phase 2: Frontend - Authentication and UI Scaffolding

**Goal:** Build the frontend components for user login/registration and establish the global authentication state.

- [ ] **Dependency Update:** Add the `provider` package to `pubspec.yaml` by running `flutter pub add provider`.
- [ ] **Project Restructuring:** Create the new directory structure within the `lib/` folder as specified in `DESIGN.md` (`models`, `providers`, `screens/auth`, etc.).
- [ ] **Data Models:** Create `user.dart` and `product.dart` model classes to represent the data from the API.
- [ ] **Create Reusable Audio Widgets:** Develop a custom `PrimaryButton` widget that incorporates the project's styling and automatically plays `AudioService.playClickSound()` on press. Additionally, create a `Clickable` wrapper widget that can be wrapped around any other widget (like an `IconButton` or `Card`) to add the click sound on tap. This ensures consistent audio feedback and promotes code reuse.
- [ ] **State Management:** Implement `auth_provider.dart` using `ChangeNotifier`. It will handle login, logout, storing the auth token securely, and exposing the user's authentication state.
- [ ] **Authentication Screens:** Create the `login_screen.dart` and `register_screen.dart` UI with the necessary `TextFormField`s and buttons.
- [ ] **API Service Update:** Add `login()` and `register()` methods to `api_service.dart`.
- [ ] **Root-Level Logic:** Update `main.dart` to use `ChangeNotifierProvider`. Implement the initial routing logic that checks for a stored token and navigates to the correct home screen (`Visitor`, `User`, or `Villager`).

### Phase 2: Post-Implementation Checklist
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run `dart_fix` and `analyze_files` and fix any issues. Run `dart_format`.
- [ ] Run any existing tests to ensure they all pass.
- [ ] Re-read this `IMPLEMENTATION.md` file.
- [ ] Update the **Journal** and check off completed tasks.
- [ ] Use `git diff` to verify changes, create a commit message, and present it for approval.
- [ ] **Await user approval before committing or moving to the next phase.**

---

## Phase 3: Backend - Product Management Logic

**Goal:** Secure the product endpoints and implement the logic for multi-image support and farm name association.

- [ ] **Secure Endpoints:** Apply the authentication middleware to the `POST /products`, `PUT /products/:id`, and `DELETE /products/:id` endpoints.
- [ ] **Update `Create Product` Endpoint:** Modify `POST /products` to associate the new product with the logged-in villager (`owner_id`) and handle multiple image uploads, saving records to the `product_images` table.
- [ ] **Implement `Update` & `Delete` Logic:** Ensure `PUT /products/:id` and `DELETE /products/:id` can only be performed by the product's owner.
- [ ] **Update `Get Products` Endpoint:** Modify `GET /products` to perform a `JOIN` with the `users` table to include the `farm_name` and a `JOIN` with `product_images` to return a list of all associated image URLs for each product.

### Phase 3: Post-Implementation Checklist
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Re-read this `IMPLEMENTATION.md` file.
- [ ] Update the **Journal** and check off completed tasks.
- [ ] Use `git diff` to verify changes, create a commit message, and present it for approval.
- [ ] **Await user approval before committing or moving to the next phase.**

---

## Phase 4: Frontend - Villager Product Management UI

**Goal:** Build the user interface for villagers to manage their products.

- [ ] **Villager Dashboard:** Create the `villager_dashboard_screen.dart` which fetches and displays only the products owned by the logged-in villager.
- [ ] **Update Product Forms:**
    - Heavily modify `add_product_screen.dart` to become the primary form for creating/editing products.
    - Add fields for `category`, `low_stock_threshold`, and a UI for uploading multiple images.
- [ ] **API Service Update:** Implement methods in `api_service.dart` for creating, updating, and deleting products, ensuring they send the JWT in the headers.
- [ ] **Update Product Card:** Modify `product_card.dart` to display the `farm_name`. Create the `image_gallery_swiper.dart` widget to display multiple images.

### Phase 4: Post-Implementation Checklist
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run `dart_fix`, `analyze_files`, and `dart_format`.
- [ ] Run tests to ensure they all pass.
- [ ] Re-read this `IMPLEMENTATION.md` file.
- [ ] Update the **Journal** and check off completed tasks.
- [ ] Use `git diff` to verify changes, create a commit message, and present it for approval.
- [ ] **Await user approval before committing or moving to the next phase.**

---

## Phase 5: Notification System

**Goal:** Implement the backend email service and a simple frontend notification display.

- [ ] **Backend Dependency:** Add `nodemailer` to `backend/package.json`.
- [ ] **Backend Email Service:** Create a service (`email_service.js`) responsible for sending emails. Configure it with appropriate SMTP settings (initially, can use a test service like Ethereal).
- [ ] **Backend Integration:** In the product update/sell logic, if a stock level drops below the `low_stock_threshold`, call the email service to notify the product owner.
- [ ] **Frontend In-App Notifications:** Create a basic `notification_service.dart` that can show `SnackBar` or `Toast`-like messages for user feedback (e.g., "Product Added Successfully").

### Phase 5: Post-Implementation Checklist
- [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [ ] Run all necessary backend and frontend checks.
- [ ] Re-read this `IMPLEMENTATION.md` file.
- [ ] Update the **Journal** and check off completed tasks.
- [ ] Use `git diff` to verify changes, create a commit message, and present it for approval.
- [ ] **Await user approval before committing or moving to the next phase.**

---

## Phase 6: Finalization

**Goal:** Complete the project documentation and prepare for final review.

- [ ] **Update README:** Create a comprehensive `README.md` file that explains what the application is, its features, and how to run both the frontend and backend.
- [ ] **Update GEMINI.md:** Update the `GEMINI.md` file to reflect the final architecture, features, and file layout of the application.
- [ ] **Final Review:** Ask for a final inspection of the app and the code to ensure satisfaction.

### General Instruction

*After completing any task, if you added any `TODO`s to the code or didn't fully implement something, make sure to add new tasks to this plan so that you can come back and complete them later.*
