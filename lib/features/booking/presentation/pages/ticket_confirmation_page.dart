import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../../../../core/theme/app_colors.dart';
import '../../../search/domain/entities/bus.dart';
import '../../../home/presentation/pages/main_bottom_nav.dart';
import '../../../../core/services/security_service.dart';

class TicketConfirmationPage extends StatefulWidget {
  final Bus bus;
  final List<String> selectedSeats;
  final String passengerName;
  final DateTime travelDate;
  final String? orderId;

  const TicketConfirmationPage({
    super.key,
    required this.bus,
    required this.selectedSeats,
    required this.passengerName,
    required this.travelDate,
    this.orderId,
  });

  @override
  State<TicketConfirmationPage> createState() => _TicketConfirmationPageState();
}

class _TicketConfirmationPageState extends State<TicketConfirmationPage> {
  final ScreenshotController screenshotController = ScreenshotController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _securityHash;
  String _paymentStatus = 'pending';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _paymentSub;

  @override
  void initState() {
    super.initState();
    _startPaymentListener();
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    super.dispose();
  }

  void _startPaymentListener() {
    final String? orderId = widget.orderId;
    if (orderId == null || orderId.isEmpty) {
      _paymentStatus = 'completed';
      _initSecurityHash();
      return;
    }

    _paymentStatus = 'pending';
    _paymentSub = FirebaseFirestore.instance
        .collection('payments')
        .doc(orderId)
        .snapshots()
        .listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;

      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status.isEmpty) return;

      if (status == 'completed') {
        if (mounted) {
          setState(() => _paymentStatus = 'completed');
        } else {
          _paymentStatus = 'completed';
        }
        _paymentSub?.cancel();
        _initSecurityHash();
        return;
      }

      if (status == 'failed' ||
          status == 'cancelled' ||
          status == 'canceled' ||
          status == 'error') {
        if (mounted) {
          setState(() => _paymentStatus = 'failed');
        } else {
          _paymentStatus = 'failed';
        }
        _paymentSub?.cancel();
      }
    }, onError: (_) {
      if (mounted) {
        setState(() => _paymentStatus = 'failed');
      } else {
        _paymentStatus = 'failed';
      }
    });
  }

  Future<void> _initSecurityHash() async {
    // _securityHash = SecurityService.generateTicketHash(
    //     "${widget.bus.id}-${widget.passengerName}-${widget.selectedSeats.join()}-ROYAL-VVIP-2024");
    try {
      final secret =
          await _secureStorage.read(key: 'ticket_secret') ?? 'ticket-secret';
      final hash = SecurityService.generateTicketHash(
          "${widget.bus.id}-${widget.passengerName}-${widget.selectedSeats.join()}-$secret");
      if (mounted) {
        setState(() => _securityHash = hash);
      }
    } catch (_) {
      final fallbackHash = SecurityService.generateTicketHash(
          "${widget.bus.id}-${widget.passengerName}-${widget.selectedSeats.join()}-ticket-secret");
      if (mounted) {
        setState(() => _securityHash = fallbackHash);
      }
    }
  }

  Future<void> _downloadTicket() async {
    try {
      final image = await screenshotController.capture();
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File(
                '${directory.path}/royal_ticket_${DateTime.now().millisecondsSinceEpoch}.png')
            .create();
        await imagePath.writeAsBytes(image);
        await Gal.putImage(imagePath.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Majestic Ticket Secured & Saved! 🛡️"),
                backgroundColor: AppColors.accent),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to secure ticket: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentStatus == 'pending') {
      return Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Waiting for payment confirmation",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Please approve the payment on your phone to unlock your ticket.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainBottomNav()),
                      (route) => false,
                    ),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: Colors.white.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "BACK TO HOME",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_paymentStatus == 'failed') {
      return Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "Payment not completed",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "We couldn’t confirm your payment. Please try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainBottomNav()),
                      (route) => false,
                    ),
                    style: OutlinedButton.styleFrom(
                      side:
                          BorderSide(color: Colors.white.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "BACK TO HOME",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_securityHash == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final String securityHash = _securityHash!;
    bool isVVIP =
        widget.selectedSeats.any((s) => s.contains('53') || s.contains('54'));

    return Scaffold(
      backgroundColor:
          isVVIP ? const Color(0xFF0F172A) : const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainBottomNav()),
            (route) => false,
          ),
        ),
        title: Text(
          isVVIP ? "ROYAL BOARDING PASS" : "ENCRYPTED BOARDING PASS",
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isVVIP
                      ? const Color(0xFFFFD700).withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: isVVIP
                          ? const Color(0xFFFFD700).withOpacity(0.3)
                          : Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        isVVIP
                            ? Icons.workspace_premium_rounded
                            : Icons.lock_outline_rounded,
                        color: isVVIP ? const Color(0xFFFFD700) : Colors.green,
                        size: 14),
                    const SizedBox(width: 8),
                    Text(
                      isVVIP
                          ? "EXCLUSIVE ROYAL ACCESS"
                          : "END-TO-END ENCRYPTED",
                      style: TextStyle(
                          color:
                              isVVIP ? const Color(0xFFFFD700) : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Screenshot(
              controller: screenshotController,
              child: isVVIP
                  ? _buildRoyalVVIPTicket(securityHash)
                  : _buildMajesticTicket(securityHash),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: isVVIP
                      ? const LinearGradient(
                          colors: [Color(0xFFB8860B), Color(0xFFFFD700)])
                      : null,
                  borderRadius: BorderRadius.circular(20),
                  color: isVVIP ? null : Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: (isVVIP ? const Color(0xFFB8860B) : Colors.black)
                            .withOpacity(0.3),
                        blurRadius: 20)
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _downloadTicket,
                  icon: Icon(Icons.download_for_offline_rounded,
                      size: 24,
                      color: isVVIP ? Colors.black : const Color(0xFF020617)),
                  label: Text(
                    "SAVE ROYAL PASS",
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isVVIP ? Colors.black : const Color(0xFF020617)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Present this pass at the Royal Lounge for VVIP check-in.",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 9,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRoyalVVIPTicket(String securityHash) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        children: [
          // Header with Gold Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF020617), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ROYAL VVIP",
                        style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 4)),
                    const SizedBox(height: 4),
                    Text(widget.bus.name.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFFFD700), width: 2),
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFFFFD700), size: 32),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _item("CHIEF TRAVELER", widget.passengerName.toUpperCase(),
                        isGold: true),
                    _item("ROYAL SEAT", widget.selectedSeats.join(", "),
                        isGold: true),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _item("BOARDING TIME", "05:30 AM", isGold: true),
                    _item("GATE", "VVIP LOUNGE", isGold: true),
                  ],
                ),
                const SizedBox(height: 40),

                // Route Graphics
                Row(
                  children: [
                    _royalRouteNode("DAR ES SALAAM", "VIP TERMINAL"),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                              height: 1,
                              color: const Color(0xFFFFD700).withOpacity(0.3)),
                          const Icon(Icons.directions_bus_filled_rounded,
                              color: Color(0xFFFFD700), size: 20),
                        ],
                      ),
                    ),
                    _royalRouteNode("MWANZA", "ROYAL STAND", alignEnd: true),
                  ],
                ),
              ],
            ),
          ),

          _royalDashedLine(),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("VVIP AMENITIES",
                          style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                      const SizedBox(height: 16),
                      _royalAmenity(
                          Icons.restaurant_rounded, "FULL GOURMET MEAL"),
                      _royalAmenity(Icons.tv_rounded, "PERSONAL IPAD PRO"),
                      _royalAmenity(Icons.airline_seat_recline_extra_rounded,
                          "MASSAGE SEATING"),
                      _royalAmenity(Icons.wine_bar_rounded, "WELCOME DRINKS"),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.2), blurRadius: 10)
                    ],
                  ),
                  child: QrImageView(
                    data: "ROYAL-VVIP-$securityHash",
                    version: QrVersions.auto,
                    size: 100.0,
                    foregroundColor: const Color(0xFF020617),
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFD700),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: const Text(
              "POWERED BY HECHES ROYAL TRANSPORT",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                  letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMajesticTicket(String securityHash) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.bus.name.toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22)),
                    const Text("🛡️ PREMIUM EXECUTIVE",
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5)),
                  ],
                ),
                const Icon(Icons.shield_rounded,
                    color: AppColors.accent, size: 28),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _item("PASSENGER", widget.passengerName),
                    _item("SEAT(S)", widget.selectedSeats.join(", "),
                        isAccent: true),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _item("DATE",
                        DateFormat.yMMMd().format(widget.travelDate)),
                    _item("SECURE ID",
                        securityHash.substring(0, 8).toUpperCase(),
                        isAccent: true),
                  ],
                ),
              ],
            ),
          ),
          _majesticDashedLine(),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("FEATURES",
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.black26)),
                      SizedBox(height: 12),
                      Text("• 5G WIFI",
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                      Text("• CLIMATE CONTROL",
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                QrImageView(
                  data: "VALID-TICKET-$securityHash",
                  version: QrVersions.auto,
                  size: 100.0,
                  foregroundColor: const Color(0xFF020617),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String value,
      {bool isAccent = false, bool isGold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: isGold
                    ? const Color(0xFFFFD700).withOpacity(0.6)
                    : Colors.grey,
                fontSize: 8,
                fontWeight: FontWeight.w900)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isGold
                    ? Colors.white
                    : (isAccent ? AppColors.primary : Colors.black87))),
      ],
    );
  }

  Widget _royalRouteNode(String city, String sub, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(city,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14)),
        Text(sub,
            style: TextStyle(
                color: const Color(0xFFFFD700).withOpacity(0.5),
                fontSize: 8,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _royalAmenity(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFD700)),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _majesticDashedLine() {
    return Row(
      children: [
        const SizedBox(
            width: 12,
            height: 24,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Color(0xFF020617),
                    borderRadius:
                        BorderRadius.horizontal(right: Radius.circular(12))))),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                  (constraints.constrainWidth() / 10).floor(),
                  (index) => const SizedBox(
                      width: 5,
                      height: 1,
                      child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.black12)))),
            );
          }),
        ),
        const SizedBox(
            width: 12,
            height: 24,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Color(0xFF020617),
                    borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(12))))),
      ],
    );
  }

  Widget _royalDashedLine() {
    return Row(
      children: [
        const SizedBox(
            width: 12,
            height: 24,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius:
                        BorderRadius.horizontal(right: Radius.circular(12))))),
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            return Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                  (constraints.constrainWidth() / 10).floor(),
                  (index) => const SizedBox(
                      width: 5,
                      height: 1,
                      child: DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white10)))),
            );
          }),
        ),
        const SizedBox(
            width: 12,
            height: 24,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius:
                        BorderRadius.horizontal(left: Radius.circular(12))))),
      ],
    );
  }
}
