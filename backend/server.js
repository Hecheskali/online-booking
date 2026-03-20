const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const path = require("path");
require("dotenv").config({ path: path.join(__dirname, ".env") });
require("dotenv").config({ path: path.join(__dirname, "..", ".env") });

// 🔑 Initialize Firebase Admin
// You need to provide a service account key file
// const serviceAccount = require("./path-to-your-service-account-key.json");
// admin.initializeApp({
//   credential: admin.credential.cert(serviceAccount)
// });

// Or if using environment variables:
if (process.env.FIREBASE_CONFIG) {
  admin.initializeApp({
    credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_CONFIG))
  });
} else {
  // Fallback for development (if already signed in via CLI)
  try {
    admin.initializeApp();
  } catch (e) {
    console.log("Firebase Admin already initialized or missing config");
  }
}

const db = admin.firestore();

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

function sanitizeReference(value, maxLen) {
  if (value === null || value === undefined) return null;
  const raw = String(value).replace(/\s+/g, " ").trim();
  if (!raw) return null;
  const cleaned = raw.replace(/[^A-Za-z0-9 \\-_.]/g, "");
  if (!cleaned) return null;
  return cleaned.slice(0, maxLen);
}

app.get("/", (req, res) => {
  res.send("Heches Bus Booking Backend with Zenopay is Running");
});

/**
 * Zenopay Payment Proxy
 * Avoids browser CORS issues by calling Zenopay from the server.
 */
app.post("/zenopay-pay", async (req, res) => {
  try {
    const {
      buyer_email,
      buyer_name,
      buyer_phone,
      amount,
      payment_reference,
    } = req.body || {};

    console.log("🔵 /zenopay-pay fields:", {
      buyer_email,
      buyer_name,
      buyer_phone,
      amount,
      payment_reference,
    });

    if (!buyer_email || !buyer_name || !buyer_phone || !amount) {
      return res.status(400).json({
        status: "failed",
        message: "Missing required fields",
      });
    }

    const apiKey = process.env.ZENOPAY_API_KEY;
    const accountId = process.env.ZENOPAY_ACCOUNT_ID;
    const secretKey = process.env.ZENOPAY_SECRET_KEY;
    const webhookUrl = process.env.ZENOPAY_WEBHOOK_URL;
    const baseUrl = process.env.ZENOPAY_BASE_URL || "https://api.zeno.africa";
    const referenceField = process.env.ZENOPAY_REFERENCE_FIELD;
    const referenceMaxLen = Number.parseInt(
      process.env.ZENOPAY_REFERENCE_MAX_LEN || "40",
      10
    );

    if (!apiKey || !accountId) {
      return res.status(500).json({
        status: "failed",
        message: "ZENOPAY_API_KEY or ZENOPAY_ACCOUNT_ID not configured",
      });
    }

    const payload = new URLSearchParams({
      create_order: "1",
      buyer_email,
      buyer_name,
      buyer_phone,
      amount: String(amount),
      account_id: accountId,
      api_key: apiKey,
    });

    if (secretKey) {
      payload.append("secret_key", secretKey);
    }

    if (webhookUrl) {
      payload.append("webhook_url", webhookUrl);
    }

    const sanitizedReference = sanitizeReference(
      payment_reference,
      Number.isFinite(referenceMaxLen) ? referenceMaxLen : 40
    );
    if (referenceField && sanitizedReference) {
      payload.append(referenceField, sanitizedReference);
    }

    const zenoUrl = baseUrl.endsWith("/")
      ? baseUrl.slice(0, -1)
      : baseUrl;
    const zenoResponse = await fetch(zenoUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: payload.toString(),
    });

    const raw = await zenoResponse.text();
    let data = raw;
    try {
      data = JSON.parse(raw);
    } catch (_) {
      // Non-JSON response; keep raw text.
    }

    return res.status(zenoResponse.status).json({
      status_code: zenoResponse.status,
      data,
      raw,
    });
  } catch (error) {
    console.error("❌ Zenopay Proxy Error:", error);
    return res.status(502).json({
      status: "failed",
      message: "Zenopay proxy error",
    });
  }
});

/**
 * Zenopay Webhook
 * Zenopay calls this URL when a payment status changes
 */
app.post("/zenopay-webhook", async (req, res) => {
  console.log("🔵 Received Zenopay Webhook:", req.body);

  const { order_id, status, transaction_id } = req.body;

  if (!order_id) {
    return res.status(400).send("Missing order_id");
  }

  try {
    // Map Zenopay status to our app status
    const normalizedStatus = (status || '').toString().toLowerCase();
    let appStatus = 'pending';
    if (['success', 'completed', 'paid'].includes(normalizedStatus)) {
      appStatus = 'completed';
    } else if (
      ['cancelled', 'canceled', 'expired', 'timeout', 'timed_out'].includes(
        normalizedStatus
      )
    ) {
      appStatus = 'cancelled';
    } else if (['failed', 'fail', 'error'].includes(normalizedStatus)) {
      appStatus = 'failed';
    }

    // Update Firestore (match on zenoOrderId first, fallback to doc id)
    const paymentsRef = db.collection('payments');
    const matching = await paymentsRef.where('zenoOrderId', '==', order_id).get();

    if (matching.empty) {
      const paymentRef = paymentsRef.doc(order_id);
      await paymentRef.update({
        status: appStatus,
        zenoTransactionId: transaction_id || null,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        webhookRawData: req.body
      });
    } else {
      const batch = db.batch();
      matching.forEach((doc) => {
        batch.update(doc.ref, {
          status: appStatus,
          zenoTransactionId: transaction_id || null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          webhookRawData: req.body
        });
      });
      await batch.commit();
    }

    console.log(`✅ Payment ${order_id} updated to ${appStatus}`);
    res.status(200).send("OK");
  } catch (error) {
    console.error("❌ Webhook Error:", error);
    res.status(500).send("Internal Server Error");
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
