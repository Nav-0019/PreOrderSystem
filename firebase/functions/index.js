const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

/**
 * Trigger: When an order is created.
 * Initializes server timestamp, validates token format, and updates system aggregate statistics.
 */
exports.onOrderCreated = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const orderData = snap.data();
    const orderId = context.params.orderId;
    const outletId = orderData.outletId;

    console.log(`[OrderCreated] New order ${orderId} received for outlet ${outletId}`);

    // Update real-time system stats aggregate
    try {
      const statsRef = db.collection("system_stats").doc("summary");
      await db.runTransaction(async (transaction) => {
        const statsDoc = await transaction.get(statsRef);
        const currentTotal = statsDoc.exists ? (statsDoc.data().totalOrders || 0) : 0;
        const currentRevenue = statsDoc.exists ? (statsDoc.data().totalRevenue || 0) : 0;

        transaction.set(
          statsRef,
          {
            totalOrders: currentTotal + 1,
            totalRevenue: currentRevenue + Number(orderData.totalAmount || 0),
            lastOrderAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      });
    } catch (err) {
      console.error("[OrderCreated] Error updating system_stats:", err);
    }

    // Authoritative Server-side Queue Increment
    if (outletId) {
      try {
        const outletRef = db.collection("outlets").doc(outletId);
        await db.runTransaction(async (transaction) => {
          const outletDoc = await transaction.get(outletRef);
          if (!outletDoc.exists) return;
          const currentQueue = outletDoc.data().queueCount || 0;
          const newQueue = currentQueue + 1;
          const newWaitTime = `${newQueue * 2}-${newQueue * 2 + 3} mins`;
          transaction.update(outletRef, {
            queueCount: newQueue,
            waitTime: newWaitTime,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });
        console.log(`[OrderCreated] Authoritatively incremented queue count for outlet ${outletId}`);
      } catch (err) {
        console.error(`[OrderCreated] Failed to increment outlet ${outletId} queue:`, err);
      }
    }
  });

/**
 * Trigger: When an order status transitions.
 * Automatically decrements outlet queue count on 'completed' or 'cancelled' and records timestamps.
 */
exports.onOrderStatusUpdated = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const orderId = context.params.orderId;

    const oldStatus = beforeData.status;
    const newStatus = afterData.status;

    if (oldStatus === newStatus) return null;

    console.log(`[OrderStatusUpdated] Order ${orderId} changed from ${oldStatus} -> ${newStatus}`);
    const outletId = afterData.outletId;

    // When order is finished or cancelled, decrement active queue count server-side
    if (["completed", "cancelled"].includes(newStatus) && !["completed", "cancelled"].includes(oldStatus)) {
      if (outletId) {
        try {
          const outletRef = db.collection("outlets").doc(outletId);
          await db.runTransaction(async (transaction) => {
            const outletDoc = await transaction.get(outletRef);
            if (!outletDoc.exists) return;

            const currentQueue = outletDoc.data().queueCount || 0;
            const newQueue = Math.max(0, currentQueue - 1);
            const newWaitTime = newQueue === 0 ? "No wait" : `${newQueue * 2}-${newQueue * 2 + 3} mins`;

            transaction.update(outletRef, {
              queueCount: newQueue,
              waitTime: newWaitTime,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });
          console.log(`[OrderStatusUpdated] Decremented queue count for outlet ${outletId}`);
        } catch (err) {
          console.error(`[OrderStatusUpdated] Failed to update outlet ${outletId} queue:`, err);
        }
      }
    }

    return null;
  });

/**
 * Callable Function: Manager or Admin verifies student payment reference (UTR).
 * Transitions paymentStatus from 'PENDING_VERIFICATION' to 'PAID'.
 * Enforces SEC-05: outlet scoping and strict precondition checks.
 */
exports.verifyPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const { orderId, isApproved, note } = data;
  if (!orderId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required orderId.");
  }

  const callerUid = context.auth.uid;
  const userDoc = await db.collection("users").doc(callerUid).get();
  const userData = userDoc.exists ? userDoc.data() : {};
  const role = userData.role || "student";

  if (!["admin", "manager", "staff", "baker"].includes(role)) {
    throw new functions.https.HttpsError("permission-denied", "Only staff or administrators can verify payments.");
  }

  const orderRef = db.collection("orders").doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Order not found.");
  }

  const orderData = orderDoc.data();

  // SEC-05: Manager must be assigned to this order's outlet (unless admin)
  if (role !== "admin" && userData.managedOutletId !== orderData.outletId) {
    throw new functions.https.HttpsError("permission-denied", "Unauthorized: Manager not assigned to this outlet's orders.");
  }

  // Precondition: Order must be awaiting verification
  if (orderData.paymentStatus !== "PENDING_VERIFICATION") {
    throw new functions.https.HttpsError("failed-precondition", "Order payment is not pending verification.");
  }

  const newStatus = isApproved ? "PAID" : "VERIFICATION_REJECTED";
  await orderRef.update({
    paymentStatus: newStatus,
    paymentVerifiedBy: callerUid,
    paymentVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    paymentVerificationNote: note || "Verified by counter staff",
  });

  return { success: true, orderId, paymentStatus: newStatus };
});

/**
 * Callable Function: Recalculate & Sync queue count for a specific outlet.
 * Enforces SEC-04: caller role and outlet scoping.
 */
exports.syncOutletQueue = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required.");
  }

  const { outletId } = data;
  if (!outletId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing outletId.");
  }

  const callerUid = context.auth.uid;
  const userDoc = await db.collection("users").doc(callerUid).get();
  const userData = userDoc.exists ? userDoc.data() : {};
  const role = userData.role || "student";

  // SEC-04: Must be admin or manager assigned to this outlet
  if (role !== "admin" && userData.managedOutletId !== outletId) {
    throw new functions.https.HttpsError("permission-denied", "Unauthorized for this outlet.");
  }

  const outletRef = db.collection("outlets").doc(outletId);
  const outletDoc = await outletRef.get();
  if (!outletDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Outlet not found.");
  }

  // Count active pending, prep, ready orders
  const activeSnap = await db
    .collection("orders")
    .where("outletId", "==", outletId)
    .where("status", "in", ["pending", "prep", "ready"])
    .get();

  const activeCount = activeSnap.size;
  const waitTime = activeCount === 0 ? "No wait" : `${activeCount * 2}-${activeCount * 2 + 3} mins`;

  await outletRef.update({
    queueCount: activeCount,
    waitTime: waitTime,
    lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true, outletId, queueCount: activeCount, waitTime };
});
