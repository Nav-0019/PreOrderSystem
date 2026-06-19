"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setUserRole = exports.onOrderWrite = exports.onUserCreated = void 0;
const functionsV1 = require("firebase-functions/v1");
const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
// ─────────────────────────────────────────────────────────────
// 1. onUserCreated
//    Replaces Supabase's on_auth_user_created.sql trigger.
//    When Firebase Auth creates a new user, write their profile
//    doc to /users/{uid} in Firestore.
// ─────────────────────────────────────────────────────────────
exports.onUserCreated = functionsV1.auth.user().onCreate(async (user) => {
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
exports.onOrderWrite = functions.firestore.onDocumentWritten("orders/{orderId}", async (event) => {
    var _a, _b, _c, _d, _e;
    // Determine which outlet was affected
    const beforeData = (_b = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before) === null || _b === void 0 ? void 0 : _b.data();
    const afterData = (_d = (_c = event.data) === null || _c === void 0 ? void 0 : _c.after) === null || _d === void 0 ? void 0 : _d.data();
    const outletId = (_e = afterData === null || afterData === void 0 ? void 0 : afterData.outletId) !== null && _e !== void 0 ? _e : beforeData === null || beforeData === void 0 ? void 0 : beforeData.outletId;
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
    const waitTime = activeCount === 0
        ? "No wait"
        : `${activeCount * 2}-${activeCount * 2 + 3} mins`;
    // Update the outlet document
    await db.collection("outlets").doc(outletId).update({
        queueCount: activeCount,
        waitTime,
    });
    console.log(`Updated outlet ${outletId}: queue=${activeCount}, wait=${waitTime}`);
});
// ─────────────────────────────────────────────────────────────
// 3. setUserRole (HTTPS callable)
//    Admin-only: set a user's role (student / staff / admin).
//    Writes both to Firestore and as a custom auth claim.
// ─────────────────────────────────────────────────────────────
exports.setUserRole = functions.https.onCall(async (request) => {
    var _a, _b;
    const callerUid = (_a = request.auth) === null || _a === void 0 ? void 0 : _a.uid;
    if (!callerUid)
        throw new functions.https.HttpsError("unauthenticated", "Not signed in");
    // Verify caller is admin
    const callerDoc = await db.collection("users").doc(callerUid).get();
    if (((_b = callerDoc.data()) === null || _b === void 0 ? void 0 : _b.role) !== "admin") {
        throw new functions.https.HttpsError("permission-denied", "Only admins can set roles");
    }
    const { targetUid, role } = request.data;
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
//# sourceMappingURL=index.js.map