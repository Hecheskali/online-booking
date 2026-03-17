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
    } = req.body || {};

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
    let appStatus = 'pending';
    if (status === 'success' || status === 'completed') {
      appStatus = 'completed';
    } else if (status === 'failed' || status === 'cancelled') {
      appStatus = 'failed';
    }

    // Update Firestore
    const paymentRef = db.collection('payments').doc(order_id);
    await paymentRef.update({
      status: appStatus,
      zenoTransactionId: transaction_id || null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      webhookRawData: req.body
    });

    console.log(`✅ Payment ${order_id} updated to ${appStatus}`);
    res.status(200).send("OK");
  } catch (error) {
    console.error("❌ Webhook Error:", error);
    res.status(500).send("Internal Server Error");
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
