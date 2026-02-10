import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';

class PaymentService {
  // 🔑 CHANGE TO LIVE KEYS FOR REAL PAYMENTS
  // PUBLIC KEY: Found in Flutterwave Dashboard -> Settings -> API Keys
  static const String publicKey =
      "FLWPUBK_TEST-f985bfc01b86225190c2c81e267ccae8-X";
  // ENCRYPTION KEY: Found in the same place
  static const String encryptionKey = "FLWSECK_TESTb0e51a2d6335";
  static const String currency = "TZS";

  /// Real Payment wrapper using Flutterwave Standard
  Future<bool> initiateStkPush({
    required BuildContext context,
    required String phoneNumber,
    required double amount,
    required String email,
    required String fullName,
  }) async {
    // 🇹🇿 Format phone to 255XXXXXXXXX
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '255${formattedPhone.substring(1)}';
    }

    final customer = Customer(
      phoneNumber: formattedPhone,
      email: email,
      name: fullName,
    );

    final flutterwave = Flutterwave(
      publicKey: publicKey,
      currency: currency,
      redirectUrl:
          "https://heches-bus.web.app/callback", // Use your actual domain or a valid one
      txRef: "HECHES-${DateTime.now().millisecondsSinceEpoch}",
      amount: amount.toStringAsFixed(0),
      customer: customer,
      // 🇹🇿 Correct string for Tanzania Mobile Money
      paymentOptions: "mobilemoneytanzania",
      customization: Customization(
        title: "Heches Royal Transport",
        description: "Bus Ticket Payment",
        logo:
            "https://firebasestorage.googleapis.com/v0/b/online-booking-84498.appspot.com/o/logo.png?alt=media",
      ),
      // ⚠️ SET THIS TO false FOR REAL PAYMENTS
      isTestMode: false,
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);

      if (response != null) {
        // Print the FULL response so we can see the real error from Flutterwave
        debugPrint("🔵 FLUTTERWAVE FULL RESPONSE: ${response.toJson()}");

        if (response.success == true ||
            response.status?.toLowerCase() == "success") {
          return true;
        } else {
          debugPrint("❌ Payment Declined: ${response.status}");
        }
      } else {
        debugPrint("🛑 User closed the payment modal without completing.");
      }
    } catch (e) {
      debugPrint("💥 CRITICAL GATEWAY ERROR: $e");
    }
    return false;
  }
}
