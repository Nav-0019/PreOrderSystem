import { initializeApp } from 'firebase/app';
import { getFirestore, doc, writeBatch, serverTimestamp } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyB7SCRCMleBUV9VuRfNFVCe89Md2Uqxnz0",
  authDomain: "aurabake.firebaseapp.com",
  projectId: "aurabake",
  storageBucket: "aurabake.firebasestorage.app",
  messagingSenderId: "556776901551",
  appId: "1:556776901551:web:89cd2e4431d2e7e61d7d5a",
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function seed() {
  console.log("🌱 Seeding Firestore via Web SDK...");

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

  const batch = writeBatch(db);

  for (const outlet of outlets) {
    const { id, ...data } = outlet;
    const outletRef = doc(db, "outlets", id);
    batch.set(outletRef, {
      ...data,
      createdAt: serverTimestamp(),
    });

    const items = menuItems[id] || [];
    for (const item of items) {
      const { id: itemId, ...itemData } = item;
      const itemRef = doc(db, "outlets", id, "menu_items", itemId);
      batch.set(itemRef, {
        ...itemData,
        outletId: id,
        createdAt: serverTimestamp(),
      });
    }
  }

  await batch.commit();
  console.log("✅ Outlets and menu items seeded successfully!");
  process.exit(0);
}

seed().catch((err) => {
  console.error("❌ Seed failed:", err);
  process.exit(1);
});
