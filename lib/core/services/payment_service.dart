import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';

class PaymentService {
  // 🔑 CHANGE TO LIVE KEYS FOR REAL PAYMENTS
  // PUBLIC KEY: Found in Flutterwave Dashboard -> Settings -> API Keys
  static const String publicKey =
      "FLWPUBK_TEST-1dea82f210e06634ebfa7a4173df8529-X";
  // ENCRYPTION KEY: Found in the same place
  static const String encryptionKey = "FLWSECK_TEST0836eac13b4d";
  static const String currency = "TZS";

  /// Real Payment wrapper using Flutterwave Standard for Mobile Money
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

      // Print the FULL response so we can see the real error from Flutterwave
      debugPrint("🔵 FLUTTERWAVE FULL RESPONSE: ${response.toJson()}");

      if (response.success == true ||
          response.status?.toLowerCase() == "success") {
        return true;
      } else {
        debugPrint("❌ Payment Declined: ${response.status}");
      }
    } catch (e) {
      debugPrint("💥 CRITICAL GATEWAY ERROR: $e");
    }
    return false;
  }

  /// Bank Transfer Payment using Flutterwave Standard
  Future<bool> initiateBank({
    required BuildContext context,
    required String bankName,
    required double amount,
    required String email,
    required String fullName,
  }) async {
    final customer = Customer(
      email: email,
      name: fullName,
    );

    final flutterwave = Flutterwave(
      publicKey: publicKey,
      currency: currency,
      redirectUrl: "https://heches-bus.web.app/callback",
      txRef: "HECHES-BANK-${DateTime.now().millisecondsSinceEpoch}",
      amount: amount.toStringAsFixed(0),
      customer: customer,
      // 🇹🇿 Bank Transfer option for Tanzania
      paymentOptions: "banktransfer",
      customization: Customization(
        title: "Heches Royal Transport",
        description: "Bus Ticket Payment - $bankName",
        logo:
            "https://firebasestorage.googleapis.com/v0/b/online-booking-84498.appspot.com/o/logo.png?alt=media",
      ),
      isTestMode: false,
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);

      debugPrint("🔵 BANK TRANSFER RESPONSE: ${response.toJson()}");

      if (response.success == true ||
          response.status?.toLowerCase() == "success") {
        return true;
      } else {
        debugPrint("❌ Bank Transfer Declined: ${response.status}");
      }
    } catch (e) {
      debugPrint("💥 BANK TRANSFER ERROR: $e");
    }
    return false;
  }
}
