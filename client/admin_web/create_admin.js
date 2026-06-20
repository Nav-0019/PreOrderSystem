import { initializeApp } from 'firebase/app';
import { getAuth, createUserWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, setDoc, serverTimestamp } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: "AIzaSyB7SCRCMleBUV9VuRfNFVCe89Md2Uqxnz0",
  authDomain: "aurabake.firebaseapp.com",
  projectId: "aurabake",
  storageBucket: "aurabake.firebasestorage.app",
  messagingSenderId: "556776901551",
  appId: "1:556776901551:web:89cd2e4431d2e7e61d7d5a",
};

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function createAdmin() {
  console.log("🔐 Creating Master Admin Account...");
  try {
    const email = "admin@aurabake.com";
    const password = "admin123";

    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const uid = userCredential.user.uid;

    console.log(`✅ Auth created. UID: ${uid}`);

    // Create the user profile in Firestore with role 'admin'
    await setDoc(doc(db, 'users', uid), {
      uid: uid,
      email: email,
      role: 'admin',
      name: 'Super Admin',
      createdAt: serverTimestamp(),
    });

    console.log("✅ Admin user profile created in Firestore!");
    console.log("Email: admin@aurabake.com");
    console.log("Password: admin123");
    process.exit(0);
  } catch (err) {
    console.error("❌ Error creating admin:", err);
    process.exit(1);
  }
}

createAdmin();
