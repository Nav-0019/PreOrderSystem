import * as functionsV1 from "firebase-functions/v1";
import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ─────────────────────────────────────────────────────────────
// 1. onUserCreated
//    Replaces Supabase's on_auth_user_created.sql trigger.
//    When Firebase Auth creates a new user, write their profile
//    doc to /users/{uid} in Firestore.
// ─────────────────────────────────────────────────────────────
export const onUserCreated = functionsV1.auth.user().onCreate(async (user) => {
  const { uid, email, displayName } = user;

  await db.collection("users").doc(uid).set({
    uid,
    name: displayName || "Student",
    email: email || "",
    role: "student",
    isPremium: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`Created user profile for ${uid} (${email})`);
});

// ─────────────────────────────────────────────────────────────
// 2. onOrderWrite
//    Replaces Supabase's update_outlet_queue trigger.
//    When an order is created, updated, or deleted, recalculate
//    queue_count and wait_time on the parent outlet doc.
// ─────────────────────────────────────────────────────────────
export const onOrderWrite = functions.firestore.onDocumentWritten(
  "orders/{orderId}",
  async (event) => {
    // Determine which outlet was affected
    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();
    const outletId: string | undefined =
      afterData?.outletId ?? beforeData?.outletId;

    if (!outletId) {
      console.warn("onOrderWrite: no outletId found, skipping.");
      return;
    }

    // Count active orders (pending, prep, ready) for this outlet
    const activeSnapshot = await db
      .collection("orders")
      .where("outletId", "==", outletId)
      .where("status", "in", ["pending", "prep", "ready"])
      .get();

    const activeCount = activeSnapshot.size;

    // Calculate wait time (2 mins per order, same as SQL trigger)
    const waitTime =
      activeCount === 0
        ? "No wait"
        : `${activeCount * 2}-${activeCount * 2 + 3} mins`;

    // Update the outlet document
    await db.collection("outlets").doc(outletId).update({
      queueCount: activeCount,
      waitTime,
    });

    console.log(
      `Updated outlet ${outletId}: queue=${activeCount}, wait=${waitTime}`
    );
  }
);

// ─────────────────────────────────────────────────────────────
// 3. setUserRole (HTTPS callable)
//    Admin-only: set a user's role (student / staff / admin).
//    Writes both to Firestore and as a custom auth claim.
// ─────────────────────────────────────────────────────────────
export const setUserRole = functions.https.onCall(async (request) => {
  const callerUid = request.auth?.uid;
  if (!callerUid) throw new functions.https.HttpsError("unauthenticated", "Not signed in");

  // Verify caller is admin
  const callerDoc = await db.collection("users").doc(callerUid).get();
  if (callerDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "Only admins can set roles");
  }

  const { targetUid, role } = request.data as { targetUid: string; role: string };
  const validRoles = ["student", "staff", "admin"];
  if (!validRoles.includes(role)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid role");
  }

  // Update Firestore doc
  await db.collection("users").doc(targetUid).update({ role });

  // Set custom claim so Firestore rules can read it
  await admin.auth().setCustomUserClaims(targetUid, { role });

  return { success: true };
});
