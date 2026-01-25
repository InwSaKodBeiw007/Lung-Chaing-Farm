### Debugging Plan (Revised)

**Phase 1: Initial Problem Resolution & New Issues Identification (Completed)**
*   Resolved "Null is not a subtype for String" error by correcting `accessToken` key in `api_service.dart`.
*   Confirmed `debugPrint` statements are working and provide valuable data.
*   Identified two new issues:
    1.  Incorrect navigation for VILLAGER role after login.
    2.  `setState()` or `markNeedsBuild()` called during build exception in `LowStockProvider`.

---

**Phase 2: Addressing New Issues**

1.  **Address the Navigation Issue (Primary Goal):**
    *   **Hypothesis:** The `AuthWrapper` (or equivalent top-level routing logic in `main.dart`) is not correctly differentiating between `USER` and `VILLAGER` roles for initial navigation after login, or the `productlistpage` is being pushed before the role-specific page.
    *   **Investigation Steps:**
        *   **Step 2.1:** Examine `main.dart` to understand the `AuthWrapper` or primary routing logic for authenticated users. Pay close attention to how `User` roles are read and used to determine the initial route.
        *   **Step 2.2:** Examine `lib/providers/auth_provider.dart` to see how the authenticated `User` object (including its `role`) is stored and exposed to the rest of the application. Ensure the `User` object's `role` is reliably accessible.
        *   **Step 2.3:** Based on findings from 2.1 and 2.2, propose modifications to `main.dart`'s routing or `AuthWrapper` to ensure `VILLAGER`s are immediately directed to `VillagerDashboardScreen` (which likely contains `EditProductScreen` or similar functionality) instead of `OnePageMarketplaceScreen` (product list).

2.  **Address the `setState()` during build error (Secondary Goal):**
    *   **Hypothesis:** `LowStockProvider.fetchLowStockProducts` is called in `_LowStockProductsScreenState.initState` without proper deferral, causing a state update during the build cycle, leading to the `setState() or markNeedsBuild() called during build` exception.
    *   **Investigation and Fix Steps:**
        *   **Step 2.4:** Locate the call to `_fetchLowStockProducts` in `lib/screens/villager/low_stock_products_screen.dart`'s `initState` method.
        *   **Step 2.5:** Modify the `initState` method to wrap the call to `_fetchLowStockProducts` within `WidgetsBinding.instance.addPostFrameCallback((_) => ...)` or a similar mechanism (`Future.microtask`, `Future.delayed(Duration.zero)`) to defer its execution until after the first frame has been rendered. This will prevent state updates during the build cycle.

---

**Phase 3: Verification & Finalization**
*   **Step 3.1:** Once changes are implemented, manually restart the app and provide the new DTD URI.
*   **Step 3.2:** Re-test login for both `USER` and `VILLAGER` roles to verify correct navigation.
*   **Step 3.3:** Navigate to any screen that would trigger `LowStockProvider` to verify the `setState()` error is resolved.
*   **Step 3.4:** Remove temporary `debugPrint` statements.
*   **Step 3.5:** Run `dart_fix`, `dart_format`, `analyze_files`, and `run_tests`.
*   **Step 3.6:** Prepare commit message for approval.