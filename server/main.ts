import { initializeApp } from "https://esm.sh/firebase@10.12.5/app";
import { getFirestore, collection, query, onSnapshot } from 'https://esm.sh/firebase@10.12.5/firestore';
import { getAuth } from 'https://esm.sh/firebase@10.12.5/auth';
import { getMessaging, onMessage } from 'https://esm.sh/firebase@10.12.5/messaging';

// Firebase 설정
const firebaseConfig = {
    apiKey: "AIzaSyDkktcO1OB1v8ULgcZg2_PXn6NmPIF2uq4",
    authDomain: "outliner-f560b.firebaseapp.com",
    projectId: "outliner-f560b",
    storageBucket: "outliner-f560b.appspot.com",
    messagingSenderId: "18349526022",
    appId: "1:18349526022:web:09cbd370d09bfeaeff0787",
    measurementId: "G-8HVQ77H5JZ",
};

// Firebase 초기화
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const messaging = getMessaging(app);

