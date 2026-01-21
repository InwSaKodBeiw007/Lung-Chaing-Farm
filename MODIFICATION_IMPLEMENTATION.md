# MODIFICATION_IMPLEMENTATION.md

This document outlines the phased implementation plan for the low-stock monitoring and sales transaction history feature.

## Journal

### Phase 0: Initial Setup and Verification
- **Date:** 2026-01-21
- **Actions Taken:** Created `MODIFICATION_DESIGN.md`. Confirmed uncommitted changes were handled and committed.
- **Learnings:** Confirmed user's preferences on transaction data retention (keep all, external CSV export) and added API filtering for transactions.
- **Surprises:** Initial request for transaction deletion was changed to retention.
- **Deviations from Plan:** N/A

### Phase 1: Database and Backend Foundations
- **Date:** 2026-01-21
- **Actions Taken:**
    - Ran all tests (Flutter tests reported no files, Node.js tests for schema passed).
    - Modified `backend/server.js` to add `low_stock_since_date` to `products` table and create `transactions` table.
    - Created `backend/test/db_schema.test.js` and installed `mocha`.
    - Ran `dart_fix`, `analyze_files` (resolved issues in `edit_product_screen.dart`, `add_product_screen.dart`, `image_gallery_swiper.dart`), and `dart_format`.
- **Learnings:**
    - The Flutter `test` directory was empty, requiring the creation of Node.js-specific tests for backend changes.
    - Encountered and resolved several pre-existing static analysis issues in Flutter files, ensuring a cleaner codebase before proceeding.
- **Surprises:** The Flutter test directory being empty and the presence of numerous static analysis issues not directly related to the current modification.
- **Deviations from Plan:** None, all steps for Phase 1 completed as planned.

### Phase 2: Backend API Endpoints and Logic
- **Date:** 2026-01-21
- **Actions Taken:**
    - Implemented `POST /api/products/:productId/purchase` endpoint.
    - Implemented `GET /api/villager/low-stock-products` endpoint.
    - Implemented `GET /api/products/:productId/transactions` endpoint with `days` filtering.
    - Created `backend/test/api.test.js` for new API endpoints.
    - Installed `supertest` as a dev dependency.
    - Debugged and fixed race conditions in backend API tests (`low_stock_since_date` logic and transaction `beforeEach` setup).
    - Ran `dart_fix`, `analyze_files`, `flutter test` (reported no test files), and `dart_format`.
- **Learnings:**
    - The asynchronous nature of Node.js SQLite operations and `supertest` required careful handling of `done()` callbacks and chaining in test `beforeEach` blocks to avoid race conditions.
    - `async/await` with promisified database calls would significantly improve test setup robustness and readability in Node.js.
- **Surprises:** Extensive debugging required for backend tests due to asynchronous operations and test setup interactions.
- **Deviations from Plan:** None, all steps for Phase 2 completed as planned.

## Implementation Plan

### Phase 1: Database and Backend Foundations

*   [x] Run all tests to ensure the project is in a good state before starting modifications.
*   [x] **Backend:** Modify `backend/server.js` to add the `low_stock_since_date` column to the `products` table during initialization (if not exists).
*   [x] **Backend:** Create the `transactions` table in `backend/server.js` during initialization (if not exists).
*   [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [x] Run the dart_fix tool to clean up the code.
*   [x] Run the analyze_files tool one more time and fix any issues.
*   [x] Run any tests to make sure they all pass.
*   [x] Run dart_format to make sure that the formatting is correct.
*   [x] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [x] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and then present the change message to the user for approval.
*   [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [x] After commiting the change, if an app is running, use the hot_reload tool to reload it.

### Phase 2: Backend API Endpoints and Logic

*   [x] **Backend:** Implement the `POST /api/products/:productId/purchase` endpoint in `backend/server.js`.
*   [x] **Backend:** Implement the `GET /api/villager/low-stock-products` endpoint in `backend/server.js`.
*   [x] **Backend:** Implement the `GET /api/products/:productId/transactions` endpoint in `backend/server.js`.
*   [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [x] Run the dart_fix tool to clean up the code.
*   [x] Run the analyze_files tool one more time and fix any issues.
*   [x] Run any tests to make sure they all pass.
*   [x] Run dart_format to make sure that the formatting is correct.
*   [x] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [x] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

### Phase 3: Frontend - Low Stock Indicator and Routing

*   [ ] **Frontend:** Add `assets/icons/shop-cart.png` to `pubspec.yaml`.
*   [ ] **Frontend:** Create a `LowStockProvider` to manage the state of low-stock products for the Villager.
*   [ ] **Frontend:** Implement the AppBar low-stock indicator with a `Badge` widget using `shop-cart.png` for Villager users.
    *   **Description:** This will display the count of low-stock products and navigate to `LowStockProductsScreen` on tap.
*   [ ] **Frontend:** Create the `LowStockProductsScreen` (or modify `villager_dashboard_screen.dart` as a new section).
    *   **Description:** This screen will display a list of currently low-stock products for the Villager.
*   [ ] **Frontend:** Implement routing to `LowStockProductsScreen` when the AppBar icon is tapped.
*   [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

### Phase 4: Frontend - Transaction History Display

*   [ ] **Frontend:** Create the `ProductTransactionHistory` reusable widget.
    *   **Description:** This widget will fetch and display transaction details for a given `productId` using the new backend API endpoint, applying the `days` filter if needed.
*   [ ] **Frontend:** Integrate `ProductTransactionHistory` into the `LowStockProductsScreen` using an `ExpansionTile` or similar expandable UI element.
*   [ ] **Frontend:** Modify existing `product_card.dart` to be tappable and navigate to a `ProductDetailScreen`.
*   [ ] **Frontend:** Enhance `ProductDetailScreen` to display the `ProductTransactionHistory` widget for the current product.
*   [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

### Phase 5: Finalization and Review

*   [ ] Update any README.md file for the package with relevant information from the modification (if any).
*   [ ] Update any GEMINI.md file in the project directory so that it still correctly describes the app, its purpose, and implementation details and the layout of the files.
*   [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.
*   [ ] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.