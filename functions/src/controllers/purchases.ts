import * as functions from "firebase-functions";
import {admin, firestore} from "../firebase";
import axios from "axios";

const APPLE_SECRET = "35b4a0eaabb246a481870991481e231d";

const productSubscriptionPeriods = {
  "app.targetly.month": 1,
  "app.targetly.year": 12,
};

interface PurchaseVerificationData {
  productId: string;
  purchaseToken: string;
  transactionId: string;
  platform: string;
  transactionDate: string;
  receiptData: string;
  isSandbox?: boolean;
}

/**
 * Validate Apple receipt
 * @param {string} receiptData - Receipt data
 * @param {boolean} isSandbox - Whether the receipt is from sandbox environment
 * @return {Promise<any>}
 */
async function validateAppleReceipt(receiptData: string, isSandbox = false): Promise<any> {
  const validationURL = isSandbox ?
    "https://sandbox.itunes.apple.com/verifyReceipt" :
    "https://buy.itunes.apple.com/verifyReceipt";

  const response = await axios.post(validationURL, {
    "receipt-data": receiptData,
    "password": APPLE_SECRET,
  });

  if (response.data.status === 21007) {
    // Receipt is from sandbox, retry with sandbox URL
    return validateAppleReceipt(receiptData, true);
  }

  return response.data;
}

export const verifyPurchase = functions.https.onCall(
  async (request: functions.https.CallableRequest<PurchaseVerificationData>) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const {productId, receiptData, transactionId, transactionDate} = request.data;
    const userId = request.auth.uid;

    try {
      const receiptValidation = await validateAppleReceipt(receiptData);

      if (receiptValidation.status !== 0) {
        throw new Error("Receipt validation failed");
      }

      const subscriptionExpiresAt = new Date();
      subscriptionExpiresAt.setMonth(
        subscriptionExpiresAt.getMonth() +
        productSubscriptionPeriods[productId as keyof typeof productSubscriptionPeriods]
      );

      await firestore.collection("accounts").doc(userId).update({
        subscription: {
          productId,
          transactionId,
          transactionDate,
          status: "active",
          platform: "ios",
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: subscriptionExpiresAt,
        },
      });

      return {success: true};
    } catch (error) {
      console.error("Purchase verification failed:", error);
      throw new functions.https.HttpsError("internal", "Failed to verify purchase");
    }
  }
);

export const restorePurchases = functions.https.onCall(
  async (request: functions.https.CallableRequest) => {
    if (!request.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    try {
      const userId = request.auth.uid;
      const userDoc = await firestore.collection("accounts").doc(userId).get();

      if (!userDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User not found");
      }

      const userData = userDoc.data();
      const now = new Date();
      const subscriptionExpiresAt = userData?.subscription?.subscriptionExpiresAt?.toDate();

      const isActive = subscriptionExpiresAt && subscriptionExpiresAt > now;

      if (!isActive) {
        return {restored: false, message: "No active subscription found"};
      }

      return {
        restored: true,
        subscription: {
          productId: userData?.subscriptionId,
          status: "active",
          platform: "ios",
          updatedAt: userData?.updatedAt,
          expiresAt: subscriptionExpiresAt,
        },
      };
    } catch (error) {
      console.error("Purchase restoration failed:", error);
      throw new functions.https.HttpsError("internal", "Failed to restore purchases");
    }
  }
);
