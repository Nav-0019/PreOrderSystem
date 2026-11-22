# 📊 AuraBake — Complete Feature Status Matrix

**Document Version:** 1.0.0  
**Audit Date:** November 22, 2026  
**Auditor:** Senior Full-Stack Software Architect, QA & Security Engineer  
**Status Legend:**
- **WORKING**: Verified functioning end-to-end against live Firestore / UI.
- **PARTIALLY WORKING**: Feature functions with caveats, missing edge cases, or client-side workarounds.
- **UI ONLY**: Visual screen/component exists, but has no live backend connection or uses hardcoded mock data.
- **BROKEN**: Feature fails during execution (e.g. throws exception, rejected by security rules, or unhandled errors).
- **NOT IMPLEMENTED**: Feature is completely absent from the codebase.
- **BLOCKED**: Implementation is blocked by another broken module or security policy.

---

## 1. Customer Application Module (`client/food_app`)

| Module | Feature | UI Status | Backend Status | Database Status | End-to-End Status | Problem / Root Cause | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Authentication** | Student Registration | WORKING | WORKING | WORKING | **WORKING** | Enforces `@presidencyuniversity.in` domain. Writes `users/{uid}`. | Medium |
| **Authentication** | Customer Login | WORKING | WORKING | WORKING | **WORKING** | Standard Firebase Auth. Saves email via `SharedPreferences`. | High |
| **Authentication** | Password Reset | WORKING | WORKING | WORKING | **WORKING** | Sends reset email via `sendPasswordResetEmail`. | Medium |
| **Authentication** | OTP Email Verification | UI ONLY | NOT IMPLEMENTED | NOT IMPLEMENTED | **UI ONLY** | Screen is purely aesthetic; tapping button navigates to home without verifying token. | Medium |
| **Profile** | View Profile Data | WORKING | WORKING | WORKING | **WORKING** | Displays name, email, student ID, and membership badges. | Low |
| **Profile** | Upload Profile Photo | WORKING | WORKING | PARTIALLY WORKING | **PARTIALLY WORKING** | Converts camera/gallery image to Base64 string directly in Firestore document; bloats record size. | High |
| **Outlets** | Real-Time Outlet List | WORKING | WORKING | WORKING | **WORKING** | Streams `/outlets` collection. Shows queue count and estimated wait times. | Critical |
| **Outlets** | Open / Closed Filtering | WORKING | WORKING | WORKING | **WORKING** | Tapping closed outlet blocks navigation to menu. Status chip reflects `isOpen`. | High |
| **Outlets** | Stall Search | WORKING | WORKING | Local State | **WORKING** | Client-side filter on outlet name and tagline. | Low |
| **Menu** | Live Menu Streaming | UI ONLY | BROKEN | PARTIALLY WORKING | **BROKEN** | MenuScreen accepts static `Outlet` object. Firestore subcollection changes do not trigger parent listeners. New items never appear. | **Critical** |
| **Menu** | Category Pill Filtering | WORKING | PARTIALLY WORKING | Local State | **PARTIALLY WORKING** | Categories derived on-the-fly from item strings. If no items exist, categories disappear. | Medium |
| **Menu** | Item Availability Filter | WORKING | WORKING | WORKING | **WORKING** | Sold-out items are hidden from list. | High |
| **Cart** | Cart Item Management | WORKING | Local State | Local State | **WORKING** | Reactive state via `CartProvider`. Quantity increment, decrement, and removal work cleanly. | High |
| **Cart** | Premium Priority Discount | WORKING | Local State | Local State | **WORKING** | Automatically applies 10% discount and priority tagging if `isPremium == true`. | Medium |
| **Cart** | Pickup Slot Selection | UI ONLY | NOT IMPLEMENTED | NOT IMPLEMENTED | **UI ONLY** | Hardcoded dropdown strings (`12:30 PM - 12:40 PM`). Capacity `3/20` is hardcoded. No `/time_slots` collection queried. | **Critical** |
| **Checkout** | Shop UPI QR Payment | WORKING | WORKING | WORKING | **WORKING** | Dynamic UPI URI rendered via `QrImageView`. Copies UPI ID, collects UTR, marks order as paid. | High |
| **Orders** | Order Placement | WORKING | WORKING | WORKING | **WORKING** | Client-side transaction writes `/orders` and increments `/outlets/{id}.queueCount`. | High |
| **Orders** | Active / Past History | WORKING | WORKING | WORKING | **WORKING** | Real-time `streamMyOrders()` splits active vs completed orders with client-side timestamp sorting. | Medium |
| **Tracking** | Live Order Tracking | WORKING | WORKING | WORKING | **WORKING** | Real-time `streamSingleOrder()` updates steps: Ordered -> In Queue -> Preparing -> Ready. | High |
| **Tracking** | Order Cancellation | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | No cancel button exists in UI, despite FAQ stating orders can be cancelled before preparation. | High |
| **Handover** | Counter Pickup QR | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | When order is ready, customer receives celebration text but NO counter handover QR/token to show staff. | **Critical** |
| **Notifications** | Order Notifications | UI ONLY | NOT IMPLEMENTED | NOT IMPLEMENTED | **UI ONLY** | Screen renders 3 hardcoded mock notifications. No Firestore listener or Firebase Cloud Messaging (FCM). | High |
| **Support** | Bug & Issue Reporting | WORKING | BROKEN | BLOCKED | **BROKEN** | Form submits to `/support_reports`, which is rejected with 403 Forbidden because no security rule exists. | High |
| **Membership** | AuraBake Premium Upgrade | WORKING | Local State | PARTIALLY WORKING | **PARTIALLY WORKING** | Toggles `isPremium` in user provider, but no payment gateway is integrated to process actual ₹99 fee. | Low |

---

## 2. Manager/Staff Application Module (`client/food_app/lib/screens/staff`)

| Module | Feature | UI Status | Backend Status | Database Status | End-to-End Status | Problem / Root Cause | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Auth & Setup** | Manager Registration | WORKING | WORKING | WORKING | **WORKING** | Registers with `role: 'manager'`. Prompts for Baker Reg No and Outlet ID. | High |
| **Auth & Setup** | Outlet Auto-Creation | PARTIALLY WORKING | BROKEN | BLOCKED | **BROKEN** | Manager registration attempts auto-create outlet if ID doesn't exist; fails silently due to rules checking role during creation. | High |
| **Profile** | Edit Manager Profile | WORKING | WORKING | WORKING | **WORKING** | Updates name, phone, registration number, and `managedOutletId`. | Medium |
| **Profile** | Upload Manager Photo | WORKING | WORKING | PARTIALLY WORKING | **PARTIALLY WORKING** | Saves Base64 photo in user document. | Low |
| **Shop Management** | Toggle Shift Online/Offline | WORKING | WORKING | WORKING | **WORKING** | Updates `/outlets/{id}.isOpen` in real time. Reflected on customer home. | High |
| **Shop Management** | Configure Shop UPI VPA | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | No screen or field exists for managers to configure their shop UPI ID or QR code. | **Critical** |
| **Menu** | Add Menu Item Form | BROKEN | PARTIALLY WORKING | PARTIALLY WORKING | **BROKEN** | Form collides with mobile keyboard; Base64 image encoding freezes UI; fails if `managedOutletId` is null. | **Critical** |
| **Menu** | Toggle Item Availability | WORKING | WORKING | WORKING | **WORKING** | Switches `isAvailable` in `/outlets/{id}/menu_items/{itemId}` in real time. | High |
| **Menu** | Edit Item Details & Price | NOT IMPLEMENTED | PARTIALLY WORKING | NOT IMPLEMENTED | **NOT IMPLEMENTED** | No UI exists to edit an existing item name, price, or prep time. | High |
| **Menu** | Delete Menu Item | NOT IMPLEMENTED | PARTIALLY WORKING | NOT IMPLEMENTED | **NOT IMPLEMENTED** | Service method `deleteMenuItem()` exists in Dart, but no button exists in UI. | Medium |
| **Queue** | Live Order Queue Stream | WORKING | WORKING | WORKING | **WORKING** | Real-time `streamOutletOrders()` displays incoming orders for the manager's assigned outlet. | **Critical** |
| **Queue** | Start Prep & Timer | WORKING | WORKING | WORKING | **WORKING** | Updates order status to `prep`, writes `prepStartedAt`, and calculates countdown from item prep times. | High |
| **Queue** | Mark Order Ready | WORKING | WORKING | WORKING | **WORKING** | Updates status to `ready`. Customer tracking screen reacts instantly. | High |
| **Handover** | Mark Order Completed | WORKING | WORKING | WORKING | **WORKING** | Marks status `completed`, decrements `queueCount`, and recalculates `waitTime`. | High |
| **Handover** | Scan Customer Pickup QR | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | Manager has no scanner to verify customer identity or pickup token before handing over food. | **Critical** |
| **Analytics** | Manager Sales & Revenue | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | Manager has zero visibility into daily revenue, order volume, or popular items. | Medium |
| **Archive** | Past Order History | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | Once marked completed, orders vanish from queue; manager cannot view past order receipts. | High |

---

## 3. Administrator Web Portal (`client/admin_web`)

| Module | Feature | UI Status | Backend Status | Database Status | End-to-End Status | Problem / Root Cause | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Authentication** | Admin Web Login | WORKING | WORKING | WORKING | **WORKING** | Verifies `role === 'admin'` from Firestore document before granting portal access. | High |
| **Overview** | System Stats Summary | WORKING | BROKEN | BROKEN | **PARTIALLY WORKING** | Downloads ALL orders client-side and calculates total revenue with `.reduce()`. Severe scalability flaw. | **Critical** |
| **Overview** | Outlets Status List | WORKING | WORKING | WORKING | **WORKING** | Real-time `onSnapshot` displays all stalls, current queue count, and open/closed badge. | Medium |
| **Live Queue** | Real-Time Order Stream | WORKING | WORKING | WORKING | **WORKING** | Shows all active campus orders. Advance status button updates Firestore transactions. | High |
| **Live Queue** | User Detail Enrichment | PARTIALLY WORKING | PARTIALLY WORKING | WORKING | **PARTIALLY WORKING** | Executes individual `getDoc` calls inside `Promise.all` for every order (N+1 query bottleneck). | Medium |
| **Menu** | Global Item Listing | WORKING | WORKING | WORKING | **WORKING** | Uses `collectionGroup(db, 'menu_items')` to display all menu items across all campus outlets. | Medium |
| **Menu** | Global Availability Toggle | WORKING | WORKING | WORKING | **WORKING** | Admin can toggle item availability on/off across any outlet. | Medium |
| **Menu** | Add New Menu Item | UI ONLY | NOT IMPLEMENTED | NOT IMPLEMENTED | **BROKEN** | `+ Add Item` button has no `onClick` handler or modal attached; does nothing. | High |
| **Analytics** | Performance & Sales Chart | UI ONLY | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | 100% placeholder component (`BarChart3` icon with dummy text). | Low |
| **Outlets** | Create / Edit / Delete Outlet | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | Admin portal has no interface to provision new campus food stalls or delete old ones. | **Critical** |
| **Outlets** | Assign Manager to Outlet | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | No interface to link manager user accounts to outlet documents. | **Critical** |
| **Users** | User Directory & RBAC | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | Admin cannot view registered students, promote users to staff/admin, or ban abusive users. | High |
| **Slots** | Pickup Slot & Capacity Mgr | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | No interface to manage 15-minute slot capacity or view congestion heatmaps. | High |
| **Payments** | UPI Gateway & Settlement | NOT IMPLEMENTED | NOT IMPLEMENTED | NOT IMPLEMENTED | **NOT IMPLEMENTED** | No interface to audit merchant UPI VPAs or review customer payment transaction references. | High |
