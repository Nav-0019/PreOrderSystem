# 📊 AuraBake — Complete Feature Status Matrix

**Document Version:** 2.0.0  
**Updated Date:** November 28, 2026  
**Auditor:** Senior Full-Stack Software Architect, QA & Security Engineer  
**Status Legend:**
- **WORKING**: Verified functioning end-to-end against live Firestore / UI.
- **PARTIALLY WORKING**: Feature functions with documented constraints (e.g. manual reference capture).
- **UI ONLY**: Visual screen/component exists, but has no live backend connection.
- **NOT IMPLEMENTED**: Feature is not yet present.

---

## 1. Customer Application Module (`client/food_app`)

| Module | Feature | UI Status | Backend Status | Database Status | End-to-End Status | Implementation Details |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Authentication** | Student Registration | WORKING | WORKING | WORKING | **WORKING** | Enforces `@presidencyuniversity.in` domain. Writes profile to `users/{uid}`. |
| **Authentication** | Customer Login | WORKING | WORKING | WORKING | **WORKING** | Standard Firebase Auth. Remembers credentials securely. |
| **Authentication** | Password Reset | WORKING | WORKING | WORKING | **WORKING** | Sends reset email via `sendPasswordResetEmail`. |
| **Profile** | View Profile Data | WORKING | WORKING | WORKING | **WORKING** | Displays name, email, student ID, and membership badges. |
| **Profile** | Upload Profile Photo | WORKING | WORKING | WORKING | **WORKING** | Uploads image to profile document. |
| **Outlets** | Real-Time Outlet List | WORKING | WORKING | WORKING | **WORKING** | Streams `/outlets` collection. Shows queue count and estimated wait times. |
| **Outlets** | Open / Closed Filtering | WORKING | WORKING | WORKING | **WORKING** | Reflects `isOpen`. Tapping closed outlet prompts user. |
| **Outlets** | Stall Search | WORKING | WORKING | Local State | **WORKING** | Client-side filter on outlet name and tagline. |
| **Menu** | Live Menu Streaming | WORKING | WORKING | WORKING | **WORKING** | Streams canonical `/menu_items` collection indexed by `outletId`. |
| **Menu** | Category Pill Filtering | WORKING | WORKING | Local State | **WORKING** | Categories derived dynamically from outlet items. |
| **Menu** | Item Availability Filter | WORKING | WORKING | WORKING | **WORKING** | Sold-out items are hidden from customer view in real-time. |
| **Cart** | Cart Item Management | WORKING | Local State | Local State | **WORKING** | Reactive state via `CartProvider`. Quantity increment, decrement, and removal. |
| **Cart** | Premium Priority Discount | WORKING | Local State | Local State | **WORKING** | Automatically applies 10% discount and priority tagging if `isPremium == true`. |
| **Cart** | Pickup Slot Selection | WORKING | WORKING | WORKING | **WORKING** | Customer chooses preferred dispatch slot; persisted in order document. |
| **Checkout** | Shop UPI QR Payment | WORKING | WORKING | WORKING | **PARTIALLY WORKING** | Dynamic UPI QR URI rendered. Validates UTR input and records as `PENDING_VERIFICATION`. Counter staff verifies payment reference before approval. |
| **Orders** | Order Placement | WORKING | WORKING | WORKING | **WORKING** | Client creates order atomically; Cloud Functions (`onOrderCreated`) authoritatively increments outlet queue metrics. |
| **Orders** | Active / Past History | WORKING | WORKING | WORKING | **WORKING** | Real-time `streamMyOrders()` splits active vs completed orders with client-side sort. |
| **Tracking** | Live Order Tracking | WORKING | WORKING | WORKING | **WORKING** | Real-time `streamSingleOrder()` updates steps: Ordered -> In Queue -> Preparing -> Ready. Accurate payment state badge (`PENDING_VERIFICATION` vs `PAID`). |
| **Tracking** | Order Cancellation | WORKING | WORKING | WORKING | **WORKING** | Order cancellation allowed if pending; Cloud Functions (`onOrderStatusUpdated`) authoritatively decrements queue count. |
| **Handover** | Counter Pickup Token Verification | WORKING | WORKING | WORKING | **WORKING** | Student presents dynamic QR and 4-digit pickup token; manager manually verifies token in confirmation dialog before handover. |
| **Support** | Bug & Issue Reporting | WORKING | WORKING | WORKING | **WORKING** | Form submits to `/support_reports`, accessible by Admin in Settings Hub. |
| **Membership** | AuraBake Premium Upgrade | WORKING | Local State | WORKING | **PARTIALLY WORKING** | Toggles `isPremium` in user provider. |

---

## 2. Manager/Staff Application Module (`client/food_app/lib/screens/staff`)

| Module | Feature | UI Status | Backend Status | Database Status | End-to-End Status | Implementation Details |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Auth & Setup** | Manager Registration | WORKING | WORKING | WORKING | **WORKING** | Registers with `role: 'manager'` and binds `managedOutletId`. |
| **Profile** | Edit Manager Profile | WORKING | WORKING | WORKING | **WORKING** | Updates name, phone, registration number, and assigned outlet. |
| **Shop Management** | Toggle Shift Online/Offline | WORKING | WORKING | WORKING | **WORKING** | Updates `/outlets/{id}.isOpen` in real time. Reflected on customer home. |
| **Shop Management** | Configure Shop UPI VPA | WORKING | WORKING | WORKING | **WORKING** | Configured per outlet in Firestore (`upiId`). |
| **Menu** | Add Menu Item Form | WORKING | WORKING | WORKING | **WORKING** | Adds item to canonical `/menu_items` with outlet scoping. |
| **Menu** | Toggle Item Availability | WORKING | WORKING | WORKING | **WORKING** | Switches `isAvailable` in `/menu_items/{itemId}` in real time. |
| **Menu** | Edit / Delete Item | WORKING | WORKING | WORKING | **WORKING** | Managed in Menu Management and staff inventory. |
| **Queue** | Live Order Queue Stream | WORKING | WORKING | WORKING | **WORKING** | Real-time `streamOutletOrders()` displays incoming orders for the assigned outlet. |
| **Queue** | Start Prep & Countdown Timer | WORKING | WORKING | WORKING | **WORKING** | Updates status to `prep`, writes `prepStartedAt`, and runs countdown timer. |
| **Queue** | Mark Order Ready | WORKING | WORKING | WORKING | **WORKING** | Updates status to `ready`. Customer tracking screen displays pickup QR. |
| **Handover** | Handover Verification Dialog | WORKING | WORKING | WORKING | **WORKING** | Manager compares the student's 4-digit pickup token in confirmation dialog before marking order completed. |
| **Archive** | Past Order History | WORKING | WORKING | WORKING | **WORKING** | Dedicated Past Orders tab in `BakerQueueScreen` displays historical order logs. |

---

## 3. Administrator Web Portal (`client/admin_web`)

| Module | Feature | UI Status | Backend Status | Database Status | End-to-End Status | Implementation Details |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Authentication** | Admin Web Login | WORKING | WORKING | WORKING | **WORKING** | Secure login (hardcoded credentials removed, password reset enabled). |
| **Overview** | System Stats Summary | WORKING | WORKING | WORKING | **WORKING** | Real-time `onSnapshot` with `system_stats` aggregates and order velocity metrics. |
| **Overview** | Dynamic Dispatch Schedule | WORKING | WORKING | WORKING | **WORKING** | Day-of-week custom dispatch windows with real Firestore slots & order counts. |
| **Live Queue** | Real-Time Order Stream | WORKING | WORKING | WORKING | **WORKING** | Live order stream with status advancement and queue count synchronization. |
| **Menu** | Menu Catalog & Pricing | WORKING | WORKING | WORKING | **WORKING** | Full cross-outlet menu catalog with search, availability toggles, and deletion. |
| **Approvals** | Menu Item Approvals Desk | WORKING | WORKING | WORKING | **WORKING** | Review manager submissions; one-click Approve / Reject actions. |
| **Settings Hub** | Customer Queries & Reports | WORKING | WORKING | WORKING | **WORKING** | Customer dispute desk, recorded refund status tracking, resolution notes, counter logging. |
| **Settings Hub** | Manager & Stall Governance | WORKING | WORKING | WORKING | **WORKING** | Recalculate & Sync queue, emergency stall intake toggle, terminal UPI config. |
| **Settings Hub** | Order Emergency Doctor | WORKING | WORKING | WORKING | **WORKING** | Search by Order ID/Token -> Force Ready, Complete, Full Refund, Cancel & Void. |
| **Settings Hub** | Platform Gateway & Preferences| WORKING | WORKING | WORKING | **WORKING** | Campus brand title, master UPI ID, operating hours, convenience fees, audio chimes. |
| **Analytics** | Analytics Reporting Desk | WORKING | WORKING | WORKING | **WORKING** | Order velocity charts, outlet distribution, time-slot performance analytics. |
