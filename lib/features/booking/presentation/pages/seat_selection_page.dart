import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/domain/entities/bus.dart';
import 'passenger_details_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final Bus bus;
  const SeatSelectionPage({super.key, required this.bus});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final List<int> selectedSeats = [];

  double _calculateTotal() {
    double total = 0;
    for (var seat in selectedSeats) {
      if (seat == 53 || seat == 54) {
        total += widget.bus.price * 1.3;
      } else {
        total += widget.bus.price;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildLegend(),
                _buildBusLayout(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBookingSummary(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          widget.bus.name.toUpperCase(),
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendItem(
              "Available", Colors.white, Colors.black12, Icons.chair_rounded),
          _legendItem("VVIP", const Color(0xFFFFD700).withOpacity(0.1),
              const Color(0xFFFFD700), Icons.workspace_premium_rounded),
          _legendItem("Selected", AppColors.primary, AppColors.primary,
              Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, Color border, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: border),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBusLayout() {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            _buildCockpit(),
            const SizedBox(height: 40),
            _buildVVIPSection(),
            const SizedBox(height: 30),
            _buildEconomySection(1, 20),
            const SizedBox(height: 20),
            _buildCenterFeatures(),
            const SizedBox(height: 20),
            _buildEconomySection(21, 52),
          ],
        ),
      ),
    );
  }

  Widget _buildCockpit() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          _buildFeatureLabel(Icons.sensor_door_outlined, "FRONT DOOR"),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.background, shape: BoxShape.circle),
            child: const Icon(Icons.settings_input_component_rounded,
                color: AppColors.textMuted, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildVVIPSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
            const SizedBox(width: 8),
            Text(
              "ROYAL VVIP CLASS",
              style: TextStyle(
                  color: const Color(0xFFB8860B),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
          ],
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 110,
                height: 140,
                child: _buildSeatItem(53, isVVIP: true),
              ),
              const SizedBox(width: 15),
              SizedBox(
                width: 110,
                height: 140,
                child: _buildSeatItem(54, isVVIP: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenterFeatures() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Left Center Door
              _buildFeatureLabel(Icons.sensor_door_outlined, "CENTER DOOR"),
              const SizedBox(width: 20),
              // Toilet correctly placed at the side, NOT in the aisle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.textMuted.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wc_rounded,
                        color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "TOILET",
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Indication of the clear passing way (Aisle)
          const Padding(
            padding: EdgeInsets.only(left: 120),
            child: Icon(Icons.arrow_downward_rounded,
                color: Colors.black12, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureLabel(IconData icon, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildEconomySection(int start, int end) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
        ),
        itemCount: ((end - start + 1) / 4 * 5).toInt(),
        itemBuilder: (context, index) {
          if (index % 5 == 2) return const SizedBox();
          int row = index ~/ 5;
          int col = index % 5;
          int seatNum = start + (row * 4) + (col > 2 ? col - 1 : col);
          if (seatNum > end) return const SizedBox();
          return _buildSeatItem(seatNum);
        },
      ),
    );
  }

  Widget _buildSeatItem(int seatNum, {bool isVVIP = false}) {
    final isSelected = selectedSeats.contains(seatNum);
    return GestureDetector(
      onTap: () => setState(() {
        if (isSelected) {
          selectedSeats.remove(seatNum);
        } else {
          selectedSeats.add(seatNum);
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isVVIP
                  ? const Color(0xFFFFD700).withOpacity(0.05)
                  : Colors.white),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isVVIP ? const Color(0xFFFFD700) : Colors.black12),
            width: isVVIP || isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppColors.premiumShadow : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isVVIP
                      ? Icons.airline_seat_flat_rounded
                      : Icons.chair_rounded,
                  color: isSelected
                      ? Colors.white
                      : (isVVIP
                          ? const Color(0xFFB8860B)
                          : AppColors.textMuted.withOpacity(0.5)),
                  size: isVVIP ? 32 : 18,
                ),
                const SizedBox(height: 6),
                Text(
                  isVVIP ? "V$seatNum" : seatNum.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isVVIP
                            ? const Color(0xFFB8860B)
                            : AppColors.textPrimary),
                    fontWeight: FontWeight.w900,
                    fontSize: isVVIP ? 12 : 12,
                  ),
                ),
                if (isVVIP) ...[
                  const SizedBox(height: 8),
                  Text(
                    "PREMIUM",
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFFB8860B).withOpacity(0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ],
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: ZoomIn(
                  child: const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${selectedSeats.length} SEATS SELECTED",
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(
                  "TZS ${_calculateTotal().toStringAsFixed(0)}",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppColors.premiumShadow,
            ),
            child: ElevatedButton(
              onPressed: selectedSeats.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PassengerDetailsPage(
                            bus: widget.bus,
                            selectedSeats:
                                selectedSeats.map((s) => "Seat $s").toList(),
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: const Text("CONTINUE",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
