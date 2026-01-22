# Implementation Plan: Refresh Tokens and Token Revocation

## Journal

### Phase 1: Database Setup and Environment Variables
- [x] Add `cookie-parser` to backend dependencies.
- [x] Update `.env` to include new JWT expiration times (for access and refresh tokens).
- [x] Modify `backend/server.js` to initialize the `refresh_tokens` table.
- [x] Create a helper function in `backend/server.js` (or a new file) to generate `jti` for refresh tokens.
- [x] Create a helper function in `backend/server.js` (or a new file) to hash refresh tokens.
- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [ ] Create/modify unit tests for testing the database setup.
- [ ] Run the dart_fix tool to clean up the code.
- [ ] Run the analyze_files tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run dart_format to make sure that the formatting is correct.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, use the hot_reload tool to reload it.

### Phase 2: Implement Login Flow Modifications

- [ ] Modify `POST /auth/login` endpoint to:
    - [ ] Generate short-lived Access Token.
    - [ ] Generate long-lived Refresh Token with `jti`.
    - [ ] Hash Refresh Token.
    - [ ] Retrieve `user_id` from the `users` table based on `email` (from authenticated user).
    - [ ] Store Refresh Token hash, `jti`, `user_id`, `expires_at`, and `created_at` in `refresh_tokens` table.
    - [ ] Send Access Token in response body.
    - [ ] Set Refresh Token in `HttpOnly`, `Secure` cookie using `res.cookie()`.
- [ ] Create/modify unit tests for the modified login endpoint.
- [ ] Run the dart_fix tool to clean up the code.
- [ ] Run the analyze_files tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run dart_format to make sure that the formatting is correct.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, use the hot_reload tool to reload it.

### Phase 3: Implement Refresh Token Endpoint

- [ ] Create new `POST /auth/refresh` endpoint to:
    - [ ] Extract Refresh Token from `HttpOnly` cookie.
    - [ ] Verify Refresh Token's signature and expiration using `JWT_SECRET`.
    - [ ] Extract `email`, `role`, and `jti` from the Refresh Token's payload.
    - [ ] Retrieve `user_id` from the `users` table based on `email`.
    - [ ] Query `refresh_tokens` table using `jti`, `user_id`, and `expires_at` to find a valid, unexpired token.
    - [ ] Compare hash of received Refresh Token with `token_hash` from database.
    - [ ] If valid:
        - [ ] Delete old Refresh Token record from `refresh_tokens` table.
        - [ ] Generate new short-lived Access Token.
        - [ ] Generate new long-lived Refresh Token with new `jti`.
        - [ ] Hash new Refresh Token.
        - [ ] Store new Refresh Token hash, new `jti`, `user_id`, `expires_at`, `created_at` in `refresh_tokens` table.
        - [ ] Send new Access Token in response body.
        - [ ] Set new Refresh Token in `HttpOnly`, `Secure` cookie.
    - [ ] If invalid or no match, return 401 Unauthorized and clear Refresh Token cookie.
- [ ] Create/modify unit tests for the refresh token endpoint.
- [ ] Run the dart_fix tool to clean up the code.
- [ ] Run the analyze_files tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run dart_format to make sure that the formatting is correct.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be虑```markdown
# Implementation Plan: Refresh Tokens and Token Revocation

## Journal

### Phase 1: Database Setup and Environment Variables
- [x] Add `cookie-parser` to backend dependencies.
- [x] Update `.env` to include new JWT expiration times (for access and refresh tokens).
- [x] Modify `backend/server.js` to initialize the `refresh_tokens` table.
- [x] Create a helper function in `backend/server.js` (or a new file) to generate `jti` for refresh tokens.
- [x] Create a helper function in `backend/server.js` (or a new file) to hash refresh tokens.
- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [ ] Create/modify unit tests for testing the database setup.
- [ ] Run the dart_fix tool to clean up the code.
- [ ] Run the analyze_files tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run dart_format to make sure that the formatting is correct.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, use the hot_reload tool to reload it.

### Phase 2: Implement Login Flow Modifications

- [ ] Modify `POST /auth/login` endpoint to:
    - [ ] Generate short-lived Access Token.
    - [ ] Generate long-lived Refresh Token with `jti`.
    - [ ] Hash Refresh Token.
    - [ ] Retrieve `user_id` from the `users` table based on `email` (from authenticated user).
    - [ ] Store Refresh Token hash, `jti`, `user_id`, `expires_at`, and `created_at` in `refresh_tokens` table.
    - [ ] Send Access Token in response body.
    - [ ] Set Refresh Token in `HttpOnly`, `Secure` cookie using `res.cookie()`.
- [ ] Create/modify unit tests for the modified login endpoint.
- [ ] Run the dart_fix tool to clean up the code.
- [ ] Run the analyze_files tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run dart_format to make sure that the formatting is correct.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, use the hot_reload tool to reload it.

### Phase 3: Implement Refresh Token Endpoint

- [ ] Create new `POST /auth/refresh` endpoint to:
    - [ ] Extract Refresh Token from `HttpOnly` cookie.
    - [ ] Verify Refresh Token's signature and expiration using `JWT_SECRET`.
    - [ ] Extract `email`, `role`, and `jti` from the Refresh Token's payload.
    - [ ] Retrieve `user_id` from the `users` table based on `email`.
    - [ ] Query `refresh_tokens` table using `jti`, `user_id`, and `expires_at` to find a valid, unexpired token.
    - [ ] Compare hash of received Refresh Token with `token_hash` from database.
    - [ ] If valid:
        - [ ] Delete old Refresh Token record from `refresh_tokens` table.
        - [ ] Generate new short-lived Access Token.
        - [ ] Generate new long-lived Refresh Token with new `jti`.
        - [ ] Hash new Refresh Token.
        - [ ] Store new Refresh Token hash, new `jti`, `user_id`, `expires_at`, `created_at` in `refresh_tokens` table.
        - [ ] Send new Access Token in response body.
        - [ ] Set new Refresh Token in `HttpOnly`, `Secure` cookie.
    - [ ] If invalid or no match, return 401 Unauthorized and clear Refresh Token cookie.
- [ ] Create/modify unit tests for the refresh token endpoint.
- [ ] Run the dart_fix tool to clean up the code.
- [ ] Run the analyze_files tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run dart_format to make sure that the formatting is correct.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, use the hot_reload tool to reload it.

### Phase 4: Implement Logout Endpoint

- [ ] Create new `POST /auth/logout` endpoint to:
    - [ ] Extract Refresh Token from `HttpOnly` cookie.
    - [ ] Verify Refresh Token's signature.
    - [ ] Extract `email`, `role`, and `jti` from Refresh Token's payload.
    - [ ] Retrieve `user_id` from the `users` table based on `email`.
    - [ ] Delete corresponding record from `refresh_tokens` table using `jti` and `user_id`.
    - [ ] Clear Refresh Token cookie.
    - [ ] Return 200 OK response.
- [ ] Create/modify unit tests for the logout endpoint.
- [ ] Run the dart_fix tool to clean up the code.
- [ ] Run the analyze_files tool one more time and fix any issues.
- [ ] Run any tests to make sure they all pass.
- [ ] Run dart_format to make sure that the formatting is correct.
- [ ] Re-read the MODIFICATION_IMPLEMENTATION.md file to see what, if anything, has changed in the implementation plan, and if it has changed, take care of anything the changes imply.
- [ ] Update the MODIFICATION_IMPLEMENTATION.md file with the current state, including any learnings, surprises, or deviations in the Journal section. Check off any checkboxes of items that have been completed.
- [ ] Use `git diff` to verify the changes that have been made, and create a suitable commit message for any changes, following any guidelines you have about commit messages. Be sure to properly escape dollar signs and backticks, and present the change message to the user for approval.
- [ ] Wait for approval. Don't commit the changes or move on to the next phase of implementation until the user approves the commit.
- [ ] After committing the change, if an app is running, use the hot_reload tool to reload it.

### Phase 5: Finalization and Review

- [ ] Update any README.md file for the package with relevant information from the modification.
- [ ] Update any GEMINI.md file in the project directory so that it still correctly describes the app, its purpose, and implementation details and the layout of the files.
- [ ] Ask the user to inspect the package (and running app, if any) and say if they are satisfied with it, or if any modifications are needed.
- [ ] Run all final tests.
- [ ] Perform a final `git status` to ensure all changes are committed.
```