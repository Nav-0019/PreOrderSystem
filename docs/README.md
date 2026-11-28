
# 🍽️ College Pre-Order Food System

## 📌 Overview
A time-slot based food pre-ordering system designed for college campuses to reduce queues, optimize food preparation, and streamline order pickup.

---

## 🎯 Objective
- Minimize waiting time
- Improve order management
- Enable efficient food preparation using time slots

---

## 👥 User Roles

### 🧑 Customer
- Browse menu
- Add items to cart
- Select time slot
- Place order
- Track order status

### 👨‍🍳 Baker (Vendor)
- Manage menu
- Set item availability
- View incoming orders
- Update order status

### 🛠️ Administrator
- Manage users
- Approve vendors
- Monitor system activity

---

## 🔄 Core User Flows

### Customer Flow
```

Login → Browse Menu → Add to Cart → Select Time Slot → Checkout → Order Confirmation → Pickup

```

### Baker Flow
```

Login → Dashboard → Manage Menu → View Orders → Update Status → Complete Orders

```

### Admin Flow
```

Login → Dashboard → Manage Users → Monitor Orders

```

---

## 🧩 Key Features

### 🛒 Ordering System
- Menu listing (grid/cards)
- Add to cart
- Quantity selection

### ⏱️ Time Slot Selection
- Fixed intervals (10–15 mins)
- Slot availability indicator

### 📦 Order Tracking
- Pending
- Preparing
- Ready for Pickup
- Completed

---

## 📱 UI Screens (MVP)

### Customer
- Login / Signup
- Menu / Home
- Cart
- Time Slot Selection
- Order Confirmation
- Order Tracking

### Baker
- Dashboard
- Menu Management
- Orders List
- Order Details

### Admin
- Dashboard
- User Management
- Vendor Approval
- Order Monitoring

---

## ⚙️ Design Constraints
- Mobile-first design
- Fast interactions (low latency UX)
- Minimal steps for ordering
- Clear time-slot visibility

---

## 🧪 MVP Scope
**Include:**
- Customer ordering flow
- Basic baker order management

**Exclude (for now):**
- Payments
- Advanced analytics
- Notification systems

---

## 🧱 Production Tech Stack & Architecture

- **Mobile Client:** Flutter 3.x (Dart) for Android and iOS
- **Admin Command Desk:** React 19, TypeScript, Vite, Tailwind CSS
- **Backend & Database:** Google Cloud Firestore & Firebase Cloud Functions
- **Authentication:** Firebase Authentication (Role-based: Student, Manager/Baker, Admin)
- **Security:** Outlet-scoped Firestore security rules with atomic transactional checkout

> **Note on Architecture Evolution:** Early initial design prototypes referenced FastAPI, PostgreSQL, and Supabase SQL triggers. These were superseded by Firebase Cloud Firestore and Cloud Functions to deliver real-time order state streams, sub-second kitchen updates, and serverless scalability. Legacy SQL files in the repository root are preserved for historical/academic review.

---

## 🎯 UX Goals
- Complete order flow in < 30 seconds
- Simple and intuitive navigation
- Clear order status visibility
```
