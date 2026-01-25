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

---

## Phase 0: Setup and Initial Verification

*   [x] Run all tests to ensure the project is in a good state before starting modifications.

## Phase 1: Backend - Database Schema Modification

**Objective:** Add the `category` field to the `products` table in the SQLite database.

*   [x] Locate the SQLite database schema definition (likely in `backend/server.js` or a separate migration script if one exists).
*   [x] Modify the `CREATE TABLE products` statement to include `category TEXT NOT NULL`.
*   [x] Implement a migration strategy for existing databases to add the `category` column (e.g., using `ALTER TABLE ADD COLUMN` if there's existing data, or dropping and re-creating for development). For initial development, we can drop and recreate the table.
*   [ ] Add default `category` values ('Vegetable' or 'Fruit') to existing product creation/seeding logic for testing purposes.
*   [ ] Create/modify unit tests for verifying the database schema change (e.g., check if the `category` column exists and can be populated).
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 2: Backend - API Modification

**Objective:** Modify the `GET /products` endpoint to support filtering by `category`.

*   [ ] Locate the `GET /products` endpoint in `backend/server.js`.
*   [ ] Modify the endpoint to accept an optional `category` query parameter.
*   [ ] Implement the SQL `WHERE` clause dynamically based on the presence of the `category` parameter.
*   [ ] Create/modify unit tests for the API endpoint to verify filtering functionality (e.g., `GET /products?category=Vegetable`).
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the hot_reload tool to reload it.

## Phase 3: Frontend - `Product` Model and `ApiService` Updates

**Objective:** Update the `Product` model to include the `category` and modify `ApiService` to use the new filtered API.

*   [ ] Modify `lib/models/product.dart` to include a `String category` field.
*   [ ] Update the `fromJson` and `toJson` methods in `Product` model to handle the new `category` field.
*   [ ] Modify `lib/services/api_service.dart`'s `fetchProducts` method to accept an optional `String? category` parameter and pass it to the backend API.
*   [ ] Create/modify unit tests for the `Product` model and `ApiService` (e.g., mock API responses with categories and verify parsing).
*   [ ] Run the dart_fix tool to clean up the code.
*   [ ] Run the analyze_files tool one more time and fix any issues.
*   [ ] Run any tests to make sure they all pass.
*   [ ] Run dart_format to make sure that the formatting is correct.
*   [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
*   [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that has been completed.
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
*   [ ] Implement a "Quick Buy Modal" (`showDialog` or `showModalBottomSheet`) that appears on `ProductCard` tap.
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
