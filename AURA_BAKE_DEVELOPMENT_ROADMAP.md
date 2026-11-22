# 🗺️ AuraBake — Engineering & Development Roadmap

**Document Version:** 1.0.0  
**Target Release:** AuraBake MVP Production Release  
**Execution Architecture:** Google Cloud / Firebase Serverless (Flutter Mobile + React/Vite Admin Web)

---

## Strategic Overview
This development roadmap translates the findings from the comprehensive AuraBake audit into an actionable, six-phase engineering plan. Each phase contains prioritized tasks, exact file targets, architectural justifications, dependencies, and explicit test verification criteria.

---

## Phase 1: Security Rules, Bug Fixes & Immediate Stability

**Objective:** Eliminate critical security vulnerabilities, fix broken forms, and unlock blocked user operations.

### Task 1.1: Patch Firestore Security Rules & Privilege Escalation
- **Problem:** Users can self-escalate to `role: 'admin'`, support reports fail with 403 Forbidden, and managers have cross-outlet write access.
- **Files:** `firebase/firestore.rules`
- **Actions:**
  1. Add strict `role` and `isPremium` immutable checks on `users/{uid}` updates:
     ```javascript
     match /users/{uid} {
       allow read: if request.auth != null && (request.auth.uid == uid || isManagerOrAdmin());
       allow write: if request.auth != null && request.auth.uid == uid &&
         (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['role', 'isPremium']));
     }
     ```
  2. Add match block for `support_reports`:
     ```javascript
     match /support_reports/{reportId} {
       allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
       allow read, update, delete: if isAdmin();
     }
     ```
  3. Scope manager menu mutations strictly to their assigned outlet:
     ```javascript
     match /outlets/{outletId}/menu_items/{itemId} {
       allow read: if true;
       allow write: if isAdmin() || (isManagerOrAdmin() && 
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.managedOutletId == outletId);
     }
     ```
- **Verification:** Run Firestore security rules unit tests verifying non-admins cannot change their role, authenticated users can write support tickets, and managers cannot mutate foreign menus.

### Task 1.2: Fix Manager Add-Item Bottom Sheet & Image Handling
- **Problem:** Form gets pushed off-screen by keyboard, lacks numeric validation, and uses synchronous Base64 encoding.
- **Files:** `client/food_app/lib/screens/staff/baker_inventory_screen.dart`
- **Actions:**
  1. Constrain bottom sheet with `SafeArea` and `DraggableScrollableSheet` with `isScrollControlled: true` so the submit button remains visible above the keyboard.
  2. Add strict input formatters (`FilteringTextInputFormatter.digitsOnly`) and explicit numeric checks for price and prep time.
  3. Add image compression (down to 300x300, JPEG quality 50) and handle network timeouts gracefully.

### Task 1.3: Enable Real-Time Menu Streaming in Customer App
- **Problem:** Customers must restart app to see new menu items or availability changes because `MenuScreen` accepts a static `Outlet` parameter.
- **Files:** `client/food_app/lib/screens/customer/menu_screen.dart`, `client/food_app/lib/services/firebase_service.dart`
- **Actions:**
  1. In `MenuScreen`, replace static `widget.outlet.menu` with a `StreamBuilder<List<Map<String, dynamic>>>` listening to `FirebaseService.streamMenuItems(widget.outlet.id)`.
  2. Update category pill generator to dynamically extract distinct categories from the live stream.
- **Verification:** Add an item in the manager app and confirm it appears on the customer's phone within 500ms without restarting.

---

## Phase 2: Unify Customer, Manager & Admin Data Flows

**Objective:** Harmonize data models, eliminate ID mismatches, and merge serverless functions.

### Task 2.1: Merge Cloud Functions & Backend Pipeline
- **Problem:** Critical serverless functions (`placeOrder`, `syncAuthUser`, `onOrderUpdated`) are marooned on `origin/master` (commit `97052f9`) and missing from `main`.
- **Files:** `firebase/functions/src/index.ts`, `firebase/firebase.json`
- **Actions:**
  1. Cherry-pick and merge `firebase/functions` from `origin/master` into `main`.
  2. Verify TypeScript build (`npm run build`) in `firebase/functions`.
  3. Wire Flutter `CartScreen` to invoke the `placeOrder` HttpsCallable function instead of performing unvalidated client writes.

### Task 2.2: Formalize Outlet Master Directory & Manager Linking
- **Problem:** Managers register by typing an unverified outlet string ID into a text field, leading to orphaned orders.
- **Files:** `client/food_app/lib/screens/auth/login_screen.dart`, `client/food_app/lib/screens/staff/edit_baker_profile_screen.dart`
- **Actions:**
  1. Replace the free-text `Outlet ID` input with a searchable dropdown populated directly from Firestore `/outlets`.
  2. Store the verified `outletId` (document ID) and `outletName` in `users/{uid}`.

### Task 2.3: Implement Dynamic Pickup Slot Management
- **Problem:** Time slots in `cart_screen.dart` are hardcoded strings without capacity checks.
- **Files:** `client/food_app/lib/screens/customer/cart_screen.dart`, `firebase/firestore.rules`
- **Actions:**
  1. Create Firestore collection `/time_slots/{slotId}` containing `startTime`, `endTime`, `currentOrders`, and `maxCapacity`.
  2. In `CartScreen`, stream active time slots for the current operational window.
  3. Disable full slots (`currentOrders >= maxCapacity`) with visual "Full" badges.

---

## Phase 3: Complete Manager/Baker Application Functionality

**Objective:** Transform the manager interface into a full-featured kitchen display and store management tool.

### Task 3.1: Manager Menu Item Editor & Deletion
- **Files:** `client/food_app/lib/screens/staff/baker_inventory_screen.dart`
- **Actions:**
  1. Add an "Edit Item" dialog allowing managers to update price, description, prep time, and photo.
  2. Add a "Delete Item" confirmation dialog connected to `FirebaseService.deleteMenuItem(outletId, itemId)`.

### Task 3.2: Manager Past Orders Archive & Daily Sales Metric
- **Files:** `client/food_app/lib/screens/staff/baker_queue_screen.dart`
- **Actions:**
  1. Add a "History" tab to `BakerQueueScreen` showing completed and rejected orders for the current day.
  2. Compute and display top metric cards: **Today's Orders**, **Items Prepared**, and **Total Daily Revenue (₹)**.

### Task 3.3: Manager Shop Configuration & UPI QR Setup
- **Files:** `client/food_app/lib/screens/staff/baker_profile_screen.dart`, `client/food_app/lib/screens/staff/edit_baker_profile_screen.dart`
- **Actions:**
  1. Add fields for **Shop UPI ID (VPA)** (e.g. `nescafe@upi`), **Merchant Display Name**, and optional **Static QR Code Image**.
  2. Persist these fields directly to `/outlets/{outletId}` so the customer checkout screen can render the exact vendor's payment QR code.

---

## Phase 4: Upgrade Admin Web Portal & Management Suite

**Objective:** Deliver a complete, professional web interface for campus cafeteria administration.

### Task 4.1: Admin Outlet Management Panel
- **Files:** `client/admin_web/src/pages/OutletManagement.tsx` (new), `client/admin_web/src/App.tsx`, `client/admin_web/src/components/DashboardLayout.tsx`
- **Actions:**
  1. Create full CRUD interface for outlets: Name, Tagline, Stall Number, Operating Hours, Status.
  2. Add modal to assign or reassign registered managers to specific outlets.

### Task 4.2: Admin User Directory & RBAC Controller
- **Files:** `client/admin_web/src/pages/UserDirectory.tsx` (new)
- **Actions:**
  1. Implement searchable data table displaying all registered users (`name`, `email`, `role`, `studentId`, `registeredNumber`).
  2. Allow administrators to toggle user roles (`student` <-> `manager` <-> `admin`) with audit logging.

### Task 4.3: Secure Financial Aggregation in Overview Dashboard
- **Problem:** `Overview.tsx` calculates revenue client-side across all orders.
- **Files:** `client/admin_web/src/pages/Overview.tsx`, `firebase/functions/src/index.ts`
- **Actions:**
  1. Connect `Overview.tsx` to read daily and monthly aggregates from `/system_stats/revenue_daily_{date}` created by Cloud Function `onOrderUpdated`.
  2. Replace placeholder `Analytics.tsx` with Recharts visual charts for peak ordering hours and top-selling food items.

---

## Phase 5: Implement Dual-QR Architecture & Pickup Handover

**Objective:** Guarantee secure payment recording and authenticated physical food handover.

### Task 5.1: Dynamic Vendor UPI Payment Flow
- **Files:** `client/food_app/lib/screens/customer/qr_payment_screen.dart`
- **Actions:**
  1. Load the outlet's registered `upiId` and `merchantName` from `/outlets/{outletId}`.
  2. Generate dynamic URI: `upi://pay?pa={outlet.upiId}&pn={outlet.name}&am={total}&cu=INR&tn=AuraBake_{orderId}`.
  3. Validate 12-digit UTR input format and save with payment metadata.

### Task 5.2: Counter Pickup Verification QR & Staff Scanner
- **Files:** `client/food_app/lib/screens/customer/tracking_screen.dart`, `client/food_app/lib/screens/staff/baker_queue_screen.dart`
- **Actions:**
  1. In `TrackingScreen`, when status is `'ready'`, display a **Pickup Token QR Code** encoding:
     `{"orderId": orderId, "token": orderId.substring(0,4), "time": timestamp}`.
  2. In `BakerQueueScreen`, add a floating camera scan button (`mobile_scanner` package).
  3. When staff scans the student's QR, verify order match and automatically transition order to `'completed'`, triggering completion audio/haptic feedback.

---

## Phase 6: Automated Testing, Concurrency & Quality Hardening

**Objective:** Ensure rock-solid reliability during high-concurrency peak campus breaks.

### Task 6.1: Concurrency & Zero-Oversell Stress Tests
- **Actions:**
  1. Write a Node.js load test script (`firebase/functions/load_test.js`) simulating 50 simultaneous order requests for the final remaining slot capacity.
  2. Verify that exactly 1 request succeeds and 49 receive standard `failed-precondition: Time slot is full` errors without deadlocks.

### Task 6.2: End-to-End Flutter Integration Tests
- **Actions:**
  1. Build automated integration test flow: Student Login -> Browse Nescafe -> Add Cold Coffee -> Select 12:30 PM Slot -> Confirm QR Payment -> Manager Queue Verification -> Advance to Ready -> Counter Handover Complete.
  2. Verify zero viewport render flex overflow on compact and large screen configurations.

---

## Top 5 Immediate Implementation Tasks

| Step | Task ID | Description | Primary Target File | Estimated Effort |
| :---: | :--- | :--- | :--- | :---: |
| **1** | **TASK-1** | Patch `firestore.rules` for support reports, role locking, and manager outlet scoping | `firebase/firestore.rules` | 1 Hour |
| **2** | **TASK-2** | Convert `MenuScreen` to live `StreamBuilder` on `menu_items` subcollection | `client/food_app/lib/screens/customer/menu_screen.dart` | 2 Hours |
| **3** | **TASK-3** | Refactor Manager `_AddItemSheet` (viewport sizing, price validation, image compression) | `client/food_app/lib/screens/staff/baker_inventory_screen.dart` | 2 Hours |
| **4** | **TASK-4** | Add Shop UPI VPA configuration to Manager Profile & link to `QrPaymentScreen` | `client/food_app/lib/screens/staff/edit_baker_profile_screen.dart` | 2 Hours |
| **5** | **TASK-5** | Merge Cloud Functions and Admin Views from `origin/master` (commit `97052f9`) into `main` | `firebase/functions`, `client/admin_web` | 3 Hours |
