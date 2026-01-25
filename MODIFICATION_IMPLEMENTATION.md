# Implementation Plan: Fixing "null is not number" in Authentication

This document outlines the phased implementation plan to address the "null is not number" error in authentication by implementing client-side JWT decoding, as detailed in `MODIFICATION_DESIGN.md`.

## Journal

### Phase 0: Initial Setup and Verification

**Date:** Sunday, January 25, 2026

**Actions Taken:**
- Confirmed a clean git working tree.
- Reviewed `GEMINI.md` and `MODIFICATION_IMPLEMENTATION.md` to understand the context of the authentication issue and recent changes.
- Outlined the problem: client-side JWT decoding for `id` and `role` is missing, leading to the "null is not number" error.
- Prepared `MODIFICATION_DESIGN.md` for user review and approval.

**Learnings:**
- The discrepancy between the stated design in `GEMINI.md` (client-side JWT decoding for `id` and `role`) and the lack of implementation details in `MODIFICATION_IMPLEMENTATION.md` strongly points to the root cause of the error.

**Surprises:**
- None.

**Deviations from Plan:**
- None.

### Phase 1: Add `jwt_decoder` Dependency and Update `User` Model

**Date:** Sunday, January 25, 2026

**Actions Taken:**
- Added `jwt_decoder: ^2.0.1` to `dependencies` in `pubspec.yaml`.
- Ran `flutter pub get` to fetch the new dependency.
- Modified `lib/models/user.dart` to include `int? id` and `String? role` fields, and updated its `fromJson` and `toJson` methods accordingly.
- Created `test/models/user_test.dart` to unit test the `User` model, ensuring correct serialization/deserialization with the new fields.
- Ran `dart fix --apply`, `flutter analyze`, `flutter test`, and `dart format .`. All tests passed, and no analysis issues were found.

**Learnings:**
- The `User` model initially had `id` and `role` as non-nullable, which was not ideal for handling potential null values from JWT payloads or initial unauthenticated states. Making them nullable improves flexibility and matches the design.

**Surprises:**
- The `User` model already contained `id` and `role` fields, though they needed to be made nullable and have their `fromJson`/`toJson` methods updated for consistency and robustness with JWT decoding.

**Deviations from Plan:**
- None.

## Implementation Phases

## Phase 1: Add `jwt_decoder` Dependency and Update `User` Model

**Objective:** Integrate the `jwt_decoder` package and update the `User` model to accommodate `id` and `role`.

*   [x] Add `jwt_decoder: ^2.0.1` to `dependencies` in `pubspec.yaml`.
*   [x] Run `flutter pub get` to fetch the new dependency.
*   [x] Modify `lib/models/user.dart` to include `int? id` and `String? role` fields, and update its `fromJson` and `toJson` methods accordingly.
*   [x] Create/modify unit tests for the `User` model to ensure correct serialization/deserialization with the new fields.
*   [x] Run `dart fix --apply` to clean up the code.
*   [x] Run `flutter analyze` and fix any issues.
*   [x] Run `flutter test` and ensure all tests pass.
*   [x] Run `dart format .` to ensure consistent code formatting.
*   [x] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes. Present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 2: Update `ApiService` for JWT Decoding

**Objective:** Implement JWT decoding and `id`/`role` extraction within `ApiService`.

*   [ ] Import `package:jwt_decoder/jwt_decoder.dart` in `lib/services/api_service.dart`.
*   [ ] Modify the `login` method in `lib/services/api_service.dart`:
    *   After receiving the `token` from the backend, use `JwtDecoder.decode(token)` to get the decoded payload.
    *   Extract `id` (as `int?`) and `role` (as `String?`) from the decoded payload.
    *   Pass these `id` and `role` values when constructing the `User` object returned by the `login` method.
*   [ ] Modify the `register` method in `lib/services/api_service.dart`:
    *   Perform similar JWT decoding and `id`/`role` extraction as in the `login` method.
    *   Pass the extracted `id` and `role` when constructing the `User` object returned by the `register` method.
*   [ ] Modify the `_loadUserFromToken` method in `lib/services/api_service.dart` to:
    *   Decode the stored token using `JwtDecoder.decode()`.
    *   Extract `id`, `email`, and `role` from the decoded token.
    *   Construct and return a `User` object with these values.
*   [ ] Create/modify unit tests for `ApiService` to verify correct JWT decoding and user object creation during login, registration, and `_loadUserFromToken`. Mock `http.post` responses with sample JWTs.
*   [ ] Run `dart fix --apply` to clean up the code.
*   [ ] Run `flutter analyze` and fix any issues.
*   [ ] Run `flutter test` and ensure all tests pass.
*   [ ] Run `dart format .` to ensure consistent code formatting.
*   [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes. Present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 3: Update `AuthProvider` and Refine Usage

**Objective:** Ensure `AuthProvider` correctly manages the authenticated `User` object and refine the usage of `id` and `role` across the application.

*   [ ] Modify `_user` field in `lib/providers/auth_provider.dart` to be of type `User?`.
*   [ ] Update the `login` and `register` methods in `lib/providers/auth_provider.dart` to receive the fully populated `User` object from `ApiService` and set it to `_user`.
*   [ ] Update `checkAuthStatus` method in `lib/providers/auth_provider.dart` to use `ApiService._loadUserFromToken()` to get the `User` object and set it to `_user`.
*   [ ] Review relevant parts of the application (e.g., `AuthWrapper`, screens, widgets) that use `authProvider.user` to ensure they correctly handle the `User` object with `id` and `role`.
*   [ ] Add `try-catch` blocks around `JwtDecoder.decode()` calls in `ApiService` to handle potential `FormatException` for invalid tokens.
*   [ ] Run `dart fix --apply` to clean up the code.
*   [ ] Run `flutter analyze` and fix any issues.
*   [ ] Run `flutter test` and ensure all tests pass.
*   [ ] Run `dart format .` to ensure consistent code formatting.
*   [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes. Present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.

## Phase 4: Finalization and Review

**Objective:** Update documentation and perform a final review of the application.

*   [ ] Update `README.md` with any relevant information from the modification.
*   [ ] Update `GEMINI.md` to reflect the new client-side JWT decoding and `User` object structure.
*   [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.
*   [ ] Run `dart fix --apply` to clean up the code.
*   [ ] Run `flutter analyze` and fix any issues.
*   [ ] Run `flutter test` and ensure all tests pass.
*   [ ] Run `dart format .` to ensure consistent code formatting.
*   [ ] Update the `MODIFICATION_IMPLEMENTATION.md` file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
*   [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes. Present the change message to the user for approval.
*   [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
*   [ ] After commiting the change, if an app is running, use the `hot_reload` tool to reload it.