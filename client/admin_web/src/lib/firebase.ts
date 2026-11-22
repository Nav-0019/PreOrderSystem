import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || 'AIzaSyB7SCRCMleBUV9VuRfNFVCe89Md2Uqxnz0',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || 'aurabake.firebaseapp.com',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'aurabake',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || 'aurabake.firebasestorage.app',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || '556776901551',
  appId: import.meta.env.VITE_FIREBASE_APP_ID || '1:556776901551:web:31f2e208f84831d51d7d5a',
};

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
