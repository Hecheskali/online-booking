import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum PaymentInitStatus { success, pending, failed }

class PaymentInitResult {
  final PaymentInitStatus status;
  final String? message;

  const PaymentInitResult({
    required this.status,
    this.message,
  });

  bool get isSuccess => status == PaymentInitStatus.success;
  bool get isPending => status == PaymentInitStatus.pending;
}

class PaymentService {
  // 🔑 ZENOPAY CONFIGURATION
  // Replace with your actual Zenopay credentials
  static const String zenoApiKey =
      "jmdGZFu2wHrR0GFdnggKHGIV7tkootlLMKcPgli0MBLgG1KRzirIDlXs62eEJaRP2yN-DUNfnVrYGB8mD2R9PQ";
  static const String zenoAccountId = "zp94191856";
  static const String zenoSecretKey = "";
  static const String zenoEndpoint = "https://api.zeno.africa";
  static const String backendBaseUrl =
      String.fromEnvironment('BACKEND_URL', defaultValue: '');

  final Dio _dio = Dio();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initiate Payment using Zenopay
  Future<PaymentInitResult> initiateZenopayPayment({
    required BuildContext context,
    required String phoneNumber,
    required double amount,
    required String email,
    required String fullName,
    required String orderId,
  }) async {
    // 🇹🇿 Format phone to 255XXXXXXXXX
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '255${formattedPhone.substring(1)}';
    }

    try {
      // 1. Create a transaction record in Firebase Firestore first (Pending)
      await _saveTransactionToFirebase(
        orderId: orderId,
        amount: amount,
        phoneNumber: formattedPhone,
        status: 'pending',
        customerName: fullName,
      );

      // 2. Prepare Zenopay Payload
      final payload = {
        'create_order': '1',
        'buyer_email': email,
        'buyer_name': fullName,
        'buyer_phone': formattedPhone,
        'amount': amount.toStringAsFixed(0),
        // Optional: webhook_url for Zenopay to notify your backend/Firebase function
        // 'webhook_url': 'https://your-firebase-function-url.com/zenopay-webhook',
      };

      debugPrint("🔵 INITIATING ZENOPAY: $orderId for TZS $amount");

      // 3. Call Zenopay API
      final bool useBackendProxy = kIsWeb || backendBaseUrl.isNotEmpty;
      final Response response;
      if (useBackendProxy) {
        if (backendBaseUrl.isEmpty) {
          return const PaymentInitResult(
            status: PaymentInitStatus.failed,
            message:
                "Backend URL not configured. Set BACKEND_URL to your server.",
          );
        }

        response = await _dio.post(
          "$backendBaseUrl/zenopay-pay",
          data: payload,
          options: Options(
            contentType: Headers.jsonContentType,
          ),
        );
      } else {
        final directPayload = {
          ...payload,
          'account_id': zenoAccountId,
          'api_key': zenoApiKey,
        };
        if (zenoSecretKey.isNotEmpty) {
          directPayload['secret_key'] = zenoSecretKey;
        }

        response = await _dio.post(
          zenoEndpoint,
          data: directPayload,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
          ),
        );
      }

      debugPrint("🔵 ZENOPAY RESPONSE: ${response.data}");

      final result = _parseZenopayResponse(response);

      if (result.isSuccess) {
        await _updateTransactionStatus(orderId, 'completed');
      } else if (result.isPending) {
        await _updateTransactionStatus(orderId, 'pending');
      } else {
        await _updateTransactionStatus(orderId, 'failed');
        debugPrint("❌ Zenopay Payment Failed: ${response.data}");
      }

      return result;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e.response?.data) ?? e.message;
      debugPrint("💥 ZENOPAY ERROR: $message");
      await _updateTransactionStatus(orderId, 'error');
      return PaymentInitResult(
        status: PaymentInitStatus.failed,
        message: message ?? "Payment request failed",
      );
    } catch (e) {
      debugPrint("💥 ZENOPAY ERROR: $e");
      await _updateTransactionStatus(orderId, 'error');
      return PaymentInitResult(
        status: PaymentInitStatus.failed,
        message: "Unexpected payment error",
      );
    }
  }

  /// Save transaction to Firebase
  Future<void> _saveTransactionToFirebase({
    required String orderId,
    required double amount,
    required String phoneNumber,
    required String status,
    required String customerName,
  }) async {
    try {
      final user = _auth.currentUser;
      await _firestore.collection('payments').doc(orderId).set({
        'userId': user?.uid,
        'orderId': orderId,
        'amount': amount,
        'currency': 'TZS',
        'phoneNumber': phoneNumber,
        'customerName': customerName,
        'status': status,
        'provider': 'Zenopay',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Firebase Save Error: $e");
    }
  }

  /// Update transaction status in Firebase
  Future<void> _updateTransactionStatus(String orderId, String status) async {
    try {
      await _firestore.collection('payments').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("🔥 Firebase Update Error: $e");
    }
  }

  // Fallback for Bank (If Zenopay supports it, otherwise map to their flow)
  Future<PaymentInitResult> initiateBank({
    required BuildContext context,
    required String bankName,
    required double amount,
    required String email,
    required String fullName,
  }) async {
    // For now, mapping Bank to the same Zenopay flow or a custom instruction
    final String orderId = "ZEN-BANK-${DateTime.now().millisecondsSinceEpoch}";
    return await initiateZenopayPayment(
      context: context,
      phoneNumber:
          "", // Usually bank doesn't need phone for STK but Zenopay might
      amount: amount,
      email: email,
      fullName: fullName,
      orderId: orderId,
    );
  }

  PaymentInitResult _parseZenopayResponse(Response response) {
    final int statusCode = response.statusCode ?? 0;
    final dynamic data = response.data;

    String? status = _extractStatus(data);
    final String? message = _extractErrorMessage(data);

    if (status != null) {
      final String normalized = status.toLowerCase();
      if (_matchesAny(normalized, const ['success', 'completed', 'paid'])) {
        return PaymentInitResult(
          status: PaymentInitStatus.success,
          message: message,
        );
      }
      if (_matchesAny(
          normalized, const ['pending', 'processing', 'created', 'queued'])) {
        return PaymentInitResult(
          status: PaymentInitStatus.pending,
          message: message,
        );
      }
      if (_matchesAny(
          normalized, const ['fail', 'failed', 'cancel', 'error'])) {
        return PaymentInitResult(
          status: PaymentInitStatus.failed,
          message: message,
        );
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return PaymentInitResult(
        status: PaymentInitStatus.pending,
        message: message,
      );
    }

    return PaymentInitResult(
      status: PaymentInitStatus.failed,
      message: message ?? "Payment request failed",
    );
  }

  String? _extractStatus(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final String lower = data.toLowerCase();
      if (_matchesAny(
          lower, const ['success', 'completed', 'pending', 'processing'])) {
        return lower;
      }
      if (_matchesAny(lower, const ['failed', 'cancel', 'error'])) {
        return lower;
      }
      return null;
    }

    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      final String? direct = _firstString(map, const [
        'status',
        'state',
        'result',
        'payment_status',
        'order_status'
      ]);
      if (direct != null) return direct;

      final String? raw = _firstString(map, const ['raw']);
      if (raw != null) {
        final String lower = raw.toLowerCase();
        if (_matchesAny(
            lower, const ['success', 'completed', 'pending', 'processing'])) {
          return lower;
        }
        if (_matchesAny(lower, const ['failed', 'cancel', 'error'])) {
          return lower;
        }
      }

      final dynamic nested = map['data'];
      if (nested is String) {
        return nested.toLowerCase();
      }
      if (nested is Map) {
        final Map<String, dynamic> nestedMap =
            Map<String, dynamic>.from(nested);
        return _firstString(nestedMap, const [
          'status',
          'state',
          'result',
          'payment_status',
          'order_status'
        ]);
      }
    }

    return null;
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;

    if (data is Map) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(data);
      final String? direct = _firstString(
          map, const ['message', 'error', 'errors', 'detail', 'response']);
      if (direct != null) return direct;

      final dynamic nested = map['data'];
      if (nested is Map) {
        final Map<String, dynamic> nestedMap =
            Map<String, dynamic>.from(nested);
        return _firstString(
            nestedMap, const ['message', 'error', 'errors', 'detail']);
      }
    }

    return null;
  }

  String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final String key in keys) {
      final dynamic value = map[key];
      if (value == null) continue;
      if (value is String && value.trim().isNotEmpty) return value;
      if (value is List && value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
    }
    return null;
  }

  bool _matchesAny(String value, List<String> needles) {
    for (final String needle in needles) {
      if (value.contains(needle)) return true;
    }
    return false;
  }
}
