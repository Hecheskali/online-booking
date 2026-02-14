import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/domain/entities/bus.dart';
import 'ticket_confirmation_page.dart';
import '../../../../core/services/payment_service.dart';

class PaymentPage extends StatefulWidget {
  final Bus bus;
  final List<String> selectedSeats;
  final List<String> passengerNames;
  final String phone;

  const PaymentPage({
    super.key,
    required this.bus,
    required this.selectedSeats,
    required this.passengerNames,
    required this.phone,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _paymentPhoneController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  String selectedMethod = 'M-Pesa';
  String selectedPaymentType = 'mobile'; // 'mobile' or 'bank'
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentPhoneController.text = widget.phone;
  }

  @override
  void dispose() {
    _paymentPhoneController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> mobilePaymentMethods = [
    {'name': 'M-Pesa', 'icon': Icons.phone_android, 'color': Colors.red},
    {'name': 'Tigo Pesa', 'icon': Icons.phone_android, 'color': Colors.blue},
    {
      'name': 'Airtel Money',
      'icon': Icons.phone_android,
      'color': Colors.red.shade900
    },
    {'name': 'Halopesa', 'icon': Icons.phone_android, 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> bankPaymentMethods = [
    {'name': 'NMB Bank', 'icon': Icons.account_balance, 'color': Colors.blue},
    {'name': 'CRDB Bank', 'icon': Icons.account_balance, 'color': Colors.green},
    {
      'name': 'Tanzania Bank',
      'icon': Icons.account_balance,
      'color': Colors.purple
    },
    {
      'name': 'Other Banks',
      'icon': Icons.account_balance,
      'color': Colors.orange
    },
  ];

  double _calculateTotal() {
    double total = 0;
    for (var seatStr in widget.selectedSeats) {
      int seatNum =
          int.tryParse(seatStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      if (seatNum == 53 || seatNum == 54) {
        total += widget.bus.price * 1.3;
      } else {
        total += widget.bus.price;
      }
    }
    return total;
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final double totalAmount = _calculateTotal();
    final user = FirebaseAuth.instance.currentUser;

    try {
      final bool success = selectedPaymentType == 'mobile'
          ? await _paymentService.initiateStkPush(
              context: context,
              phoneNumber: _paymentPhoneController.text,
              amount: totalAmount,
              email: user?.email ?? "traveler@heches.com",
              fullName: widget.passengerNames[0],
            )
          : await _paymentService.initiateBank(
              context: context,
              bankName: selectedMethod,
              amount: totalAmount,
              email: user?.email ?? "traveler@heches.com",
              fullName: widget.passengerNames[0],
            );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (success) {
          _showSuccessAndGenerateTicket();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Payment unsuccessful or cancelled. Check your balance/PIN."),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gateway Error: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showSuccessAndGenerateTicket() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 60),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Transaction Secured!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(
              "Payment of TZS ${_calculateTotal().toStringAsFixed(0)} received. Your royal e-ticket is ready.",
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.premiumShadow,
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TicketConfirmationPage(
                        bus: widget.bus,
                        selectedSeats: widget.selectedSeats,
                        passengerName: widget.passengerNames[0],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text("VIEW MY TICKET",
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = _calculateTotal();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("PAYMENT",
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(child: _buildAmountCard(totalAmount)),
              const SizedBox(height: 32),
              _buildSectionHeader("PAYMENT METHOD"),
              const SizedBox(height: 16),
              _buildPaymentTypeSelector(),
              const SizedBox(height: 32),
              if (selectedPaymentType == 'mobile') ...[
                _buildSectionHeader("SELECT MOBILE MONEY"),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: mobilePaymentMethods
                        .map((method) => _buildSquareMethodTile(method))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionHeader("PAYMENT NUMBER"),
                const SizedBox(height: 16),
                _buildPhoneField(),
                const SizedBox(height: 12),
                const Text(
                  "You will be redirected to authorize your mobile money payment.",
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500),
                ),
              ] else ...[
                _buildSectionHeader("SELECT BANK"),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: bankPaymentMethods
                        .map((method) => _buildSquareMethodTile(method))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 32),
                _buildBankTransferInfo(),
              ],
              const SizedBox(height: 40),
              FadeInUp(child: _buildPayButton(totalAmount)),
              const SizedBox(height: 30),
              const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded,
                        size: 12, color: AppColors.textMuted),
                    SizedBox(width: 8),
                    Text("SECURED BY FLUTTERWAVE",
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5),
    );
  }

  Widget _buildPaymentTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPaymentTypeButton('mobile', 'Mobile Money'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPaymentTypeButton('bank', 'Bank Transfer'),
        ),
      ],
    );
  }

  Widget _buildPaymentTypeButton(String type, String label) {
    bool isSelected = selectedPaymentType == type;
    return GestureDetector(
      onTap: () => setState(() {
        selectedPaymentType = type;
        if (type == 'mobile') selectedMethod = 'M-Pesa';
        if (type == 'bank') selectedMethod = 'NMB Bank';
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textMuted.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected ? AppColors.softShadow : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankTransferInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_rounded, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Bank Transfer Instructions',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You will be redirected to complete your bank transfer. Please ensure you have sufficient funds in your selected bank account.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(double amount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TOTAL PAYABLE",
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text("TZS ${amount.toStringAsFixed(0)}",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text("${widget.selectedSeats.length} SEATS",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Text(widget.bus.name.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareMethodTile(Map<String, dynamic> method) {
    bool isSelected = selectedMethod == method['name'];
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = method['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 2),
          boxShadow: isSelected ? AppColors.softShadow : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(method['icon'],
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                size: 28),
            const SizedBox(height: 10),
            Text(method['name'],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: TextFormField(
        controller: _paymentPhoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1),
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
          hintText: "0xxx xxx xxx",
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
        validator: (value) {
          if (value == null || value.length < 10)
            return "Valid number required";
          return null;
        },
      ),
    );
  }

  Widget _buildPayButton(double amount) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.premiumShadow,
      ),
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handlePayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("PROCEED TO PAY",
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1)),
      ),
    );
  }
}
