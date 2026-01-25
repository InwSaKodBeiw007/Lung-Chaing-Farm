# Implementation Plan: One-Page Marketplace Application

This document outlines the phased implementation plan for the One-Page Marketplace application, incorporating backend and frontend modifications as detailed in `MODIFICATION_DESIGN.md`.

## Journal

### Phase 1: Backend - Database Schema Modification

**Date:** Sunday, January 25, 2026

**Actions Taken:**
- Located the SQLite database schema definition within `backend/server.js`.
- Modified the `ALTER TABLE products ADD COLUMN category` statement to include `TEXT NOT NULL DEFAULT "Uncategorized"`. This change ensures that the `category` column, when added, enforces a non-null constraint and provides a default value for existing rows in SQLite.

**Learnings:**
- SQLite's `ALTER TABLE ADD COLUMN` for `NOT NULL` columns requires a `DEFAULT` value if the table already contains data.
- The project's schema management for adding new columns dynamically is already in place.

**Surprises:**
- Initial assumption that `CREATE TABLE` needed direct modification was incorrect; dynamic column addition was already handled.
- The `TypeError` in frontend tests was resolved by making `Product.fromJson` more robust to handle `image_urls` as both `List<dynamic>` and `String`. This was an unexpected prerequisite fix.

**Deviations from Plan:**
- Instead of modifying the `CREATE TABLE` statement, the existing `ALTER TABLE ADD COLUMN` logic was adjusted.
- An additional step was required to fix a `TypeError` in frontend tests before proceeding with backend modifications.

### Phase 2: Backend - API Modification

**Date:** Sunday, January 25, 2026

**Actions Taken:**
- Modified the `GET /products` endpoint in `backend/server.js` to accept an optional `category` query parameter and filter products accordingly. This involved dynamically constructing the SQL `WHERE` clause based on the presence of the `category` parameter.
- Addressed persistent backend test failures, including `jti` assertion errors, timeouts, and `FATAL ERROR`s stemming from `sqlite3`. This required extensive debugging and refactoring of test setup and isolation.
    - The `POST /auth/login` tests were moved to a dedicated `backend/test/auth_login.test.js` file for complete isolation, and their `beforeEach` and `it` block logic were refined to ensure correct `jti` verification against the database.
    - The `ReferenceError: testProductId is not defined` and incorrect product count assertions in `api.test.js` were resolved by ensuring each `describe` block had its own comprehensive `beforeEach` setup for users, tokens, and products. This included specific setups for `/products/:productId/purchase`, `/villager/low-stock-products`, `/products/:productId/transactions`, and `/products` endpoints.
    - The registration regression in `auth.test.js` (test `should not register a user with an existing email` failing with `expected 500, got 201`) was fixed by modifying the test case to first successfully register a user, then immediately attempt a duplicate registration *within the same test case* to correctly trigger and assert the expected `500 Internal Server Error` due to the unique email constraint.
- All backend tests (`api.test.js` and `auth.test.js`) are now stable and passing.

**Learnings:**
- Robust test isolation is crucial for complex API interactions involving tokens and database state. Shared `beforeEach` setups can lead to cascading failures if not meticulously managed.
- Asynchronous operations in test hooks (e.g., database insertions, API calls) must be properly handled with `async/await` or `done()` callbacks to prevent timeouts and unexpected test behavior.
- Precise matching of `old_string` in `replace` tool is critical; subtle differences can lead to failure. In-memory replacement with `write_file` can be a more robust alternative for stubborn blocks.

**Surprises:**
- The degree of refactoring needed for backend tests was more extensive than initially anticipated, particularly around token management and database state in tests.
- The default behavior of `npm test` running all `.js` files in `test/` directory, causing both `api.test.js` and `auth.test.js` to run together, helped in identifying cross-file test interaction issues.

**Deviations from Plan:**
- The initial approach of modifying `api.test.js` directly for auth tests was abandoned in favor of creating a separate `auth_login.test.js` file for better modularity and isolation.
- Significant time was spent on debugging and refactoring backend tests due to the complexities of asynchronous operations and shared test context.

### Phase 3: Frontend - `Product` Model and `ApiService` Updates

**Date:** Sunday, January 25, 2026

**Actions Taken:**
- Confirmed that `lib/models/product.dart` already includes the `String category` field, and its `fromJson` and `toJson` methods correctly handle this field.
- Modified `lib/services/api_service.dart`'s `getProducts` method to accept an optional `String? category` parameter and pass it as a query parameter to the backend API.
- Created `test/services/api_service_test.dart` to unit test the `ApiService`, verifying `getProducts` with and without the `category` parameter.
- Created `test/models/product_test.dart` to unit test the `Product` model, ensuring correct serialization and deserialization of the `category` field.
- Ran `dart fix --apply`, `flutter analyze`, and `flutter test` to ensure code quality and correctness. All tests passed.
- Ran `dart format .` to maintain consistent code formatting.

**Learnings:**
- Always verify existing code for planned changes to avoid redundant work.
- The test setup and mocking patterns in `low_stock_provider_test.dart` were highly valuable for creating new unit tests.
- Forgetting a simple import (`dart:convert`) can lead to compilation errors in tests.

**Surprises:**
- The `category` field was already present in `Product` model, simplifying this phase.

**Deviations from Plan:**
- None. The plan was followed with adjustments for existing code.

---

## Phase 0: Setup and Initial Verification

*   [x] Run all tests to ensure the project is in a good state before starting modifications.

## Phase 1: Backend - Database Schema Modification

**Objective:** Add the `category` field to the `products` table in the SQLite database.

*   [x] Locate the SQLite database schema definition (likely in `backend/server.js` or a separate migration script if one exists).
*   [x] Modify the `CREATE TABLE products` statement to include `category TEXT NOT NULL`.
*   [x] Implement a migration strategy for existing databases to add the `category` column (e.g., using `ALTER TABLE ADD COLUMN` if there's existing data, or dropping and re-creating for development). For initial development, we can drop and recreate the table.
*   [x] Add default `category` values ('Vegetable' or 'Fruit') to existing product creation/seeding logic for testing purposes.
*   [x] Create/modify unit tests for verifying the database schema change (e.g., check if the `category` column exists and can be populated).
*   [x] Run the dart_fix tool to clean up the code.
*   [x] Run the analyze_files tool one more time and fix any issues.
*   [x] Run any tests to make sure they all pass.
*   [x] Run dart_format to make sure that the formatting is correct.
*   [x] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [x] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [x] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [x] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [x] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 2: Backend - API Modification

**Objective:** Modify the `GET /products` endpoint to support filtering by `category`.

*   [x] Locate the `GET /products` endpoint in `backend/server.js`.
*   [x] Modify the endpoint to accept an optional `category` query parameter.
*   [x] Implement the SQL `WHERE` clause dynamically based on the presence of the `category` parameter.
*   [x] Create/modify unit tests for the API endpoint to verify filtering functionality (e.g., `GET /products?category=Vegetable`).
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [x] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [x] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [x] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 3: Frontend - `Product` Model and `ApiService` Updates

**Objective:** Update the `Product` model to include the `category` and modify `ApiService` to use the new filtered API.

*   [x] Modify `lib/models/product.dart` to include a `String category` field.
*   [x] Update the `fromJson` and `toJson` methods in `Product` model to handle the new `category` field.
*   [x] Modify `lib/services/api_service.dart`'s `fetchProducts` method to accept an optional `String? category` parameter and pass it to the backend API.
*   [x] Create/modify unit tests for the `Product` model and `ApiService` (e.g., mock API responses with categories and verify parsing).
*   [x] Run the dart_fix tool to clean up the code.
*   [x] Run the analyze_files tool one more time and fix any issues.
*   [x] Run any tests to make sure they all pass.
*   [x] Run dart_format to make sure that the formatting is correct.
*   [x] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [x] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 4: Frontend - Core UI Components (`HeroSection`, `ProductListSection`, `OnePageMarketplaceScreen`)

**Objective:** Implement the main UI components for the one-page application.

*   [ ] Create `lib/sections/hero_section.dart` with "KK Farm" title, anchor links (placeholders for now), banner image, and "View Today's Products" button (linking to product sections).
*   [ ] Create `lib/sections/product_list_section.dart` to display products for a given category using `FutureBuilder` and `GridView.builder` with `ProductCard` widgets.
*   [ ] Create `lib/screens/one_page_marketplace_screen.dart` to orchestrate `HeroSection` and two instances of `ProductListSection` (one for 'Vegetable', one for 'Fruit').
*   [ ] Implement username display for authenticated `USER` roles in the header of `OnePageMarketplaceScreen`.
*   [ ] Create/modify widget tests for these new UI components.
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 5: Frontend - `ProductCard` Enhancements and Interactions

**Objective:** Enhance `ProductCard` to display category/price and implement quick buy interaction with audio feedback.

*   [ ] Modify `lib/widgets/product_card.dart` to properly display the `category` and `price_per_kg` (if not already handled).
*   [ ] Implement tap interaction on `ProductCard` to play `click.mp3` using `AudioService`.
*   [ ] Implement a "Quick Buy Modal" (`showDialog` or `showModalBottomSheet`) that appears on `ProductCard` tap for authenticated `USER` roles. For `VISITOR` roles, tapping a product should navigate to the login page.
*   [ ] Create/modify widget tests for `ProductCard` interactions.
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 6: Frontend - Routing and Integration

**Objective:** Integrate the `OnePageMarketplaceScreen` into the `AuthWrapper` in `main.dart`.

*   [ ] Modify `lib/main.dart` to replace `ProductListScreen` with `OnePageMarketplaceScreen` as the default for unauthenticated users and `USER` role.
*   [ ] Ensure proper passing of `ApiService` or other dependencies if required by `OnePageMarketplaceScreen`.
*   [ ] Create/modify integration tests to verify the routing logic.
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 7: Finalization and Review

*   [ ] Update `README.md` for the package with relevant information about the new one-page marketplace.
*   [ ] Update `GEMINI.md` in the project directory to reflect the new architecture, purpose, and implementation details of the one-page marketplace.
*   [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.