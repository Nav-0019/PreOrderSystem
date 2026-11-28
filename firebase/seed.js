/**
 * AuraBake Firestore Seed Script
 * Replaces seed_data.sql for Firebase.
 *
 * Usage (after setting up Firebase project):
 *   node seed.js
 *
 * Requires: npm install firebase-admin
 * Set GOOGLE_APPLICATION_CREDENTIALS to your service account key JSON path,
 * OR run `firebase login` and use the emulator.
 */

const admin = require("firebase-admin");

// ── Initialize ──────────────────────────────────────────────
// For local emulator testing, use:
//   process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
// Then initialize without a credential.
if (process.env.FIRESTORE_EMULATOR_HOST) {
  admin.initializeApp({ projectId: "YOUR_PROJECT_ID" });
} else {
  // Production: set GOOGLE_APPLICATION_CREDENTIALS env var to service account key path
  admin.initializeApp();
}

const db = admin.firestore();

async function seed() {
  console.log("🌱 Seeding Firestore...");

  // ── Outlets ──────────────────────────────────────────────
  const outlets = [
    {
      id: "o1",
      name: "Nescafe Center",
      tagline: "Hot coffee & quick bites",
      icon: "local_cafe",
      isOpen: true,
      queueCount: 0,
      waitTime: "No wait",
    },
    {
      id: "o2",
      name: "Campus Canteen",
      tagline: "Full meals & thalis",
      icon: "restaurant",
      isOpen: true,
      queueCount: 0,
      waitTime: "No wait",
    },
    {
      id: "o3",
      name: "Juice Bar",
      tagline: "Fresh juices & shakes",
      icon: "local_bar",
      isOpen: false,
      queueCount: 0,
      waitTime: "Closed",
    },
  ];

  // ── Menu Items (as subcollections under each outlet) ─────
  const menuItems = {
    o1: [
      { id: "m1", name: "Cold Coffee", description: "Thick creamy cold coffee", price: 60, category: "Beverages", icon: "coffee", isAvailable: true },
      { id: "m2", name: "Maggi", description: "Classic masala maggi", price: 40, category: "Snacks", icon: "ramen_dining", isAvailable: true },
      { id: "m3", name: "Veg Burger", description: "Aloo tikki burger with cheese", price: 55, category: "Snacks", icon: "lunch_dining", isAvailable: true },
    ],
    o2: [
      { id: "m4", name: "Veg Thali", description: "Dal, roti, sabzi, rice", price: 90, category: "Meals", icon: "dinner_dining", isAvailable: true },
      { id: "m5", name: "Chole Bhature", description: "Spicy chole with 2 bhature", price: 80, category: "Meals", icon: "breakfast_dining", isAvailable: true },
    ],
    o3: [
      { id: "m6", name: "Mango Shake", description: "Fresh mango shake", price: 50, category: "Beverages", icon: "local_bar", isAvailable: true },
    ],
  };

  const batch = db.batch();

  for (const outlet of outlets) {
    const { id, ...data } = outlet;
    const outletRef = db.collection("outlets").doc(id);
    batch.set(outletRef, {
      ...data,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Add menu items to canonical root /menu_items and outlet subcollection
    const items = menuItems[id] || [];
    for (const item of items) {
      const { id: itemId, ...itemData } = item;

      // 1. Canonical root collection (/menu_items)
      const canonicalRef = db.collection("menu_items").doc(`${id}_${itemId}`);
      batch.set(canonicalRef, {
        ...itemData,
        outletId: id,
        outletName: outlet.name,
        isApproved: true,
        approvalStatus: "approved",
        prepTime: 5,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Subcollection (/outlets/{id}/menu_items) for backward compatibility
      const subItemRef = outletRef.collection("menu_items").doc(itemId);
      batch.set(subItemRef, {
        ...itemData,
        outletId: id,
        outletName: outlet.name,
        isApproved: true,
        approvalStatus: "approved",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  await batch.commit();
  console.log("✅ Outlets and menu items seeded!");
  console.log("ℹ️  Orders will be created when users log in and place orders.");
}

seed().catch((err) => {
  console.error("❌ Seed failed:", err);
  process.exit(1);
});
