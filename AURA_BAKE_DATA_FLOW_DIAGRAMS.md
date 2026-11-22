# 🔄 AuraBake — End-to-End Data Flow Diagrams & Architecture Specifications

**Document Version:** 1.0.0  
**Target:** Engineering Architecture & Operational Data Workflows (A through M)  
**System:** AuraBake Campus Food Pre-Ordering System

---

## Architecture Overview
The AuraBake ecosystem connects three decoupled user interfaces through a unified Google Cloud / Firebase Serverless backend:
1. **Customer Mobile Client (Flutter):** Student and faculty ordering, payments, and tracking.
2. **Manager Mobile Client (Flutter):** Kitchen order dispatch, prep timers, and menu availability management.
3. **Administrator Web Portal (React/Vite):** Campus-wide oversight, stall creation, and queue monitoring.

Below are the comprehensive sequence diagrams and data definitions for Workflows **A through M**, explicitly highlighting **[EXISTING WORKING]** vs. **[PROPOSED / TO-BE-IMPLEMENTED]** flows.

---

### Workflow A & B: Admin Creates Outlet & Assigns Manager

> **Status:** **[PROPOSED]** (Currently outlets are manually seeded via `seed.js` or auto-created with errors during manager registration).

```mermaid
sequenceDiagram
    autonumber
    actor Admin as Campus Administrator
    participant Web as Admin Web Portal (React)
    participant FS as Cloud Firestore
    actor Mgr as Outlet Manager (Staff)

    Note over Admin,FS: Workflow A: Create Outlet
    Admin->>Web: Opens Outlets Panel & Clicks "+ New Outlet"
    Admin->>Web: Inputs Name ("Nescafe Center"), Tagline, Stall #, UPI VPA
    Web->>FS: POST /outlets/{outletId}
    FS-->>Web: Document Created (ID: o1)

    Note over Admin,Mgr: Workflow B: Assign Manager
    Admin->>Web: Selects Registered Staff User from User Directory
    Admin->>Web: Assigns Manager UID to Outlet "o1"
    Web->>FS: PATCH /users/{managerUid} { managedOutletId: "o1", role: "manager" }
    FS-->>Web: User Profile Updated
    Web-->>Admin: "Manager Assigned Successfully"
    
    Mgr->>FS: Manager logs into Food App
    FS-->>Mgr: Streams /users/{managerUid} with managedOutletId: "o1"
```

---

### Workflow C: Manager Opens Outlet & Configures Information

> **Status:** **[EXISTING PARTIALLY WORKING]** (Shift toggle works; operating hours and UPI configuration are proposed).

```mermaid
sequenceDiagram
    autonumber
    actor Mgr as Outlet Manager
    participant App as Staff Food App (Flutter)
    participant FS as Cloud Firestore
    participant Cust as Customer App (Flutter)

    Mgr->>App: Opens "Order Management" Screen
    Mgr->>App: Toggles Status Pill from "Offline" to "Active"
    App->>FS: updateOutlet("o1", { isOpen: true, waitTime: "No wait" })
    FS-->>Cust: streamOutlets() emits snapshot event
    Cust->>Cust: Updates Outlet Card to "Open now" with Green Badge
```

---

### Workflow D & E: Manager Adds Food Item & Customer Discovers It

> **Status:** **[CRITICAL ARCHITECTURAL FIX REQUIRED]**  
> *Existing Bug:* Manager adds item to `/outlets/{id}/menu_items`, but `CustomerHome` does not listen to subcollections, and `MenuScreen` consumes a static parameter.  
> *Proposed Flow Below Solves This:*

```mermaid
sequenceDiagram
    autonumber
    actor Mgr as Outlet Manager
    participant App as Staff Food App (Flutter)
    participant FS as Cloud Firestore
    actor Cust as Customer (Student)
    participant CustApp as Customer App (Flutter)

    Note over Mgr,FS: Workflow D: Add Food Item
    Mgr->>App: Clicks "+ Add Item" in Inventory Tab
    Mgr->>App: Enters Name ("Cold Coffee"), Price (60), Prep Time (5m), Category ("Beverages")
    App->>FS: addMenuItem("o1", { name, price: 60.0, prepTime: 5, isAvailable: true })
    FS-->>App: Subcollection Document Created (/outlets/o1/menu_items/m1)

    Note over Cust,FS: Workflow E: Customer Discovery (Live Stream)
    Cust->>CustApp: Taps "Nescafe Center" on Home Screen
    CustApp->>CustApp: Navigates to MenuScreen(outletId: "o1")
    CustApp->>FS: Subscribes to streamMenuItems("o1") via StreamBuilder
    FS-->>CustApp: Emits real-time item list including new "Cold Coffee"
    CustApp->>Cust: Displays "Cold Coffee · ₹60 · ~5m" with Add Button
```

---

### Workflow F & G: Cart, Slot Selection, Shop QR Payment & Order Placement

> **Status:** **[EXISTING WORKING WITH SHOP UPI QR; SLOTS PROPOSED FOR PRODUCTION]**

```mermaid
sequenceDiagram
    autonumber
    actor Cust as Customer (Student)
    participant App as Customer App (Flutter)
    participant FS as Cloud Firestore
    actor Merch as Merchant UPI App

    Cust->>App: Taps "+" to add 2x Cold Coffee (₹120)
    Cust->>App: Navigates to Cart Screen
    Cust->>App: Selects Verified Time Slot ("12:30 PM - 12:45 PM")
    Cust->>App: Clicks "Proceed to Pay with Shop QR →"
    
    Note over Cust,App: Workflow G: QR Payment & Order Creation
    App->>App: Opens QrPaymentScreen with dynamic URI:<br/>upi://pay?pa=nescafe@upi&pn=Nescafe&am=125&cu=INR
    Cust->>Merch: Scans QR or copies UPI ID into GPay/PhonePe & pays ₹125
    Cust->>App: Enters 12-digit Bank Reference (UTR) "432198765432"
    Cust->>App: Clicks "I Have Paid · Confirm Order"
    
    App->>FS: placeOrder(outletId: "o1", total: 125, items, UTR, slotId)
    FS->>FS: Transaction: Creates /orders/{orderId} & increments /outlets/o1.queueCount
    FS-->>App: Returns orderId ("ORD-98214")
    App->>App: Clears Cart & Navigates to TrackingScreen
```

---

### Workflow H, I & J: Kitchen Receipt, Preparation & Prep Timer

> **Status:** **[EXISTING WORKING]**

```mermaid
sequenceDiagram
    autonumber
    participant FS as Cloud Firestore
    actor Mgr as Outlet Manager (Kitchen Staff)
    participant StaffApp as Staff Food App (Flutter)
    participant CustApp as Customer Tracking Screen

    FS-->>StaffApp: streamOutletOrders("o1") emits new ticket (Status: "pending")
    StaffApp->>Mgr: Plays Audio Beep & Shows New Ticket: #ORD-98 (2x Cold Coffee)
    
    Note over Mgr,StaffApp: Workflow I: Start Preparation
    Mgr->>StaffApp: Clicks "Confirm & Start Prep"
    StaffApp->>FS: updateOrder("ORD-98214", status: "prep", prepStartedAt: now(), prepTime: 5)
    
    FS-->>CustApp: streamSingleOrder emits status: "prep"
    CustApp->>CustApp: Advances Stepper to Step 2: "Preparing"
    StaffApp->>StaffApp: Starts 5-Minute Countdown Timer on Kitchen Ticket
    
    Note over Mgr,StaffApp: Workflow J: Mark Ready
    StaffApp->>Mgr: Timer ends -> Staff clicks "Mark Ready 🎉"
    StaffApp->>FS: updateOrder("ORD-98214", status: "ready")
```

---

### Workflow K, L & M: Ready Status, Pickup Verification QR & Order Completion

> **Status:** **[PROPOSED SECURE HANDOVER PROTOCOL]**  
> *Existing:* Customer sees celebration text; staff taps button without verification.  
> *Proposed Flow Below Introduces Fraud-Proof Handover:*

```mermaid
sequenceDiagram
    autonumber
    participant FS as Cloud Firestore
    participant CustApp as Customer Tracking Screen
    actor Cust as Customer (Student)
    actor Mgr as Outlet Manager (Counter Staff)
    participant StaffApp as Staff Food App (Scanner)
    participant AdminWeb as Admin Web Live Queue

    FS-->>CustApp: streamSingleOrder emits status: "ready"
    CustApp->>CustApp: Displays "Order Ready!" + Renders Pickup Verification QR Token
    Cust->>Mgr: Walks to Nescafe Counter with Phone Displaying Pickup QR
    
    Note over Mgr,Cust: Workflow L: Counter Handover & QR Scan
    Mgr->>StaffApp: Taps Floating Camera Icon "Scan Pickup QR"
    StaffApp->>CustApp: Scans Customer's Pickup QR Token
    StaffApp->>StaffApp: Validates Token matches Order #ORD-98214
    
    Note over StaffApp,FS: Workflow M: Completion & Metric Update
    StaffApp->>FS: updateOrderStatus("ORD-98214", status: "completed")
    FS->>FS: Decrements /outlets/o1.queueCount & updates waitTime
    FS-->>CustApp: Stepper Completes -> Displays "Collected ✓"
    FS-->>AdminWeb: Live Queue removes ticket & updates Daily GMV
```

---

## Data Synchronization Contract Table

| Entity | Canonical Firestore Path | Writers | Listeners / Consumers | Real-Time Mechanism |
| :--- | :--- | :--- | :--- | :--- |
| **User Profile** | `/users/{uid}` | Self (non-restricted fields), Admin | Self (`UserProvider`), Admin (`UserDirectory`) | `snapshots()` on document |
| **Outlet Meta** | `/outlets/{outletId}` | Admin, Assigned Manager | Customers (`CustomerHome`), Admin (`Overview`) | `snapshots()` on collection |
| **Menu Catalog** | `/outlets/{outletId}/menu_items/{itemId}` | Assigned Manager, Admin | Customers (`MenuScreen`), Admin (`MenuManagement`) | `snapshots()` on subcollection |
| **Order Document**| `/orders/{orderId}` | Cloud Function (`placeOrder`) / Customer | Customer (`TrackingScreen`), Staff (`BakerQueueScreen`), Admin (`LiveQueue`) | `snapshots()` with compound query filter |
| **Time Slot** | `/time_slots/{slotId}` | Cloud Function (`placeOrder`), Admin | Customer (`CartScreen`), Admin (`SlotManager`) | `runTransaction()` locking |
| **Support Report**| `/support_reports/{reportId}` | Customer | Admin | Direct write with `serverTimestamp()` |
