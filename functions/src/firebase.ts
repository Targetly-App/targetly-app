import admin from "firebase-admin";
import {getFirestore} from "firebase-admin/firestore";

const app = admin.initializeApp();
const firestore = getFirestore(app);

export {admin, firestore};
