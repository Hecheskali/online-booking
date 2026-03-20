import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/bus.dart';
import '../../../booking/presentation/pages/seat_selection_page.dart';

class BusResultsPage extends StatelessWidget {
  final String from;
  final String to;
  final DateTime date;

  const BusResultsPage({
    super.key,
    required this.from,
    required this.to,
    required this.date,
  });

  double _calculatePrice(String from, String to) {
    final routes = {
      'Dar es Salaam-Arusha': 500.0,
      'Dar es Salaam-Mwanza': 600.0,
      'Dar es Salaam-Dodoma': 2500.0,
      'Arusha-Mwanza': 4500.0,
      'Mwanza-Dar es Salaam': 6000.0,
    };
    String key = '$from-$to';
    return routes[key] ?? 600.00;
  }

  List<Bus> _getMockBuses(double basePrice) {
    return [
      Bus(
        id: '1',
        name: 'Kilimanjaro Express',
        type: 'Luxury AC Sleeper',
        departureTime: '06:00 AM',
        arrivalTime: '02:00 PM',
        duration: '8h 00m',
        price: basePrice + 5000,
        rating: 4.9,
        availableSeats: 54,
        amenities: ['WiFi', 'Charging Port','Tv','Toilet','Water'],
        route: [from, to],
      ),
      Bus(
        id: '2',
        name: 'Tahmeed Coach',
        type: 'Executive AC Seater',
        departureTime: '08:30 AM',
        arrivalTime: '04:30 PM',
        duration: '8h 00m',
        price: basePrice,
        rating: 4.7,
        availableSeats: 54,
        amenities: ['WiFi', 'Extra Legroom','Tv','Toilet','Charging Port','Water'],
        route: [from, to],
      ),
      Bus(
        id: '3',
        name: 'Dar Express',
        type: 'Semi-Luxury AC',
        departureTime: '10:00 AM',
        arrivalTime: '06:00 PM',
        duration: '8h 00m',
        price: basePrice - 2000,
        rating: 4.7,
        availableSeats: 54,
        amenities: ['WiFi'],
        route: [from, to],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final basePrice = _calculatePrice(from, to);
    final List<Bus> mockBuses = _getMockBuses(basePrice);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, mockBuses.length),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return FadeInUp(
                    delay: Duration(milliseconds: 100 * index),
                    duration: const Duration(milliseconds: 600),
                    child: _buildBusCard(context, mockBuses[index]),
                  );
                },
                childCount: mockBuses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, int count) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: CircleAvatar(
                  radius: 100,
                  backgroundColor: Colors.white.withOpacity(0.05),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            from,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: Colors.white70, size: 20),
                          ),
                          Text(
                            to,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${date.day}/${date.month}/${date.year} • 1 Passenger • $count Buses Found",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, Bus bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeatSelectionPage(
                bus: bus,
                travelDate: date,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bus.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  bus.type,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildRatingBadge(bus.rating),
                      ],
                    ),
                    _buildRouteTimeline(bus),
                    Row(
                      children: bus.amenities
                          .map((a) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Icon(_getAmenityIcon(a),
                                    size: 16, color: AppColors.textMuted),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "TZS ",
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                            text: bus.price.toStringAsFixed(0),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.premiumShadow,
                      ),
                      child: const Text(
                        "BOOK NOW",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    if (name.contains('WiFi')) return Icons.wifi_rounded;
    if (name.contains('Charging')) return Icons.bolt_rounded;
    if (name.contains('Water')) return Icons.local_drink_rounded;
    return Icons.star_border_rounded;
  }

  Widget _buildRatingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            rating.toString(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteTimeline(Bus bus) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TimePoint(time: bus.departureTime, city: from, isStart: true),
          Expanded(child: _RouteLine(duration: bus.duration)),
          _TimePoint(time: bus.arrivalTime, city: to, isStart: false),
        ],
      ),
    );
  }
}

class _TimePoint extends StatelessWidget {
  final String time;
  final String city;
  final bool isStart;
  const _TimePoint(
      {required this.time, required this.city, required this.isStart});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isStart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(time,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textPrimary)),
        const SizedBox(height: 2),
        Text(
          city.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5),
        ),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  final String duration;
  const _RouteLine({required this.duration});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            duration,
            style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 4)
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary.withOpacity(0.5)
                      ],
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: 0,
                child: const Icon(Icons.directions_bus_filled_rounded,
                    size: 18, color: AppColors.primary),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.5),
                        AppColors.secondary
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.secondary.withOpacity(0.3),
                        blurRadius: 4)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
