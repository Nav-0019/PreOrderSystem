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
    const email = "shubhamchauhan0019@gmail.com";
    const password = "aurabake0019";

    let uid;
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      uid = userCredential.user.uid;
      console.log(`✅ Auth created. UID: ${uid}`);
    } catch (e) {
      if (e.code === 'auth/email-already-in-use') {
        console.log(`Email already exists. Signing in to grant admin access...`);
        const { signInWithEmailAndPassword } = await import('firebase/auth');
        const userCredential = await signInWithEmailAndPassword(auth, email, password);
        uid = userCredential.user.uid;
      } else {
        throw e;
      }
    }

    // Create the user profile in Firestore with role 'admin'
    await setDoc(doc(db, 'users', uid), {
      uid: uid,
      email: email,
      role: 'admin',
      name: 'Super Admin',
      createdAt: serverTimestamp(),
    });

    console.log("✅ Admin user profile created in Firestore!");
    console.log("Email: shubhamchauhan0019@gmail.com");
    console.log("Password: aurabake0019");
    process.exit(0);
  } catch (err) {
    console.error("❌ Error creating admin:", err);
    process.exit(1);
  }
}

createAdmin();
