import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/presentation/widgets/search_card.dart';
import 'dart:math' as math;
import '../../../../core/services/notification_service.dart';
import 'package:file_picker/file_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _customSoundPath;
  String? _customSoundName;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickCustomSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result != null) {
      setState(() {
        _customSoundPath = result.files.single.path;
        _customSoundName = result.files.single.name;
      });
    }
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "JOURNEY ALERTS",
                style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2),
              ),
              const SizedBox(height: 12),
              const Text(
                "Set offline reminder sounds based on your booked tickets.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Custom Sound Picker
              GestureDetector(
                onTap: () async {
                  await _pickCustomSound();
                  setSheetState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _customSoundName ?? "SELECT CUSTOM ALERT SOUND",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.add_circle_outline_rounded,
                          color: AppColors.accent, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _buildAlarmTile("30 MINUTES BEFORE", 30),
              _buildAlarmTile("15 MINUTES BEFORE", 15),
              _buildAlarmTile("10 MINUTES BEFORE", 10),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    _scheduleOfflineReminders();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "Alerts activated with ${_customSoundName ?? 'default sound'}!"),
                        backgroundColor: AppColors.accent,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text("ACTIVATE ALERTS",
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleOfflineReminders() {
    NotificationService().scheduleJourneyAlert(
      id: 1,
      title: "Bus Departure Imminent!",
      body: "Your NextGen Bus is leaving in 30 minutes. Head to the terminal!",
      scheduledDate: DateTime.now().add(const Duration(minutes: 1)),
      customSoundPath: _customSoundPath,
    );
  }

  Widget _buildAlarmTile(String title, int minutes) {
    bool isActive = false;
    return StatefulBuilder(
      builder: (context, setState) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isActive
                  ? AppColors.accent.withOpacity(0.3)
                  : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications_active_rounded,
                color: isActive ? AppColors.accent : Colors.white24, size: 20),
            const SizedBox(width: 16),
            Text(title,
                style: TextStyle(
                    color: isActive ? Colors.white : Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            Switch(
              value: isActive,
              activeThumbColor: AppColors.accent,
              onChanged: (val) => setState(() => isActive = val),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMajesticHeader(context),
            _buildMainContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildMajesticHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF020617), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(60),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: MajesticNaturePainter(progress: _controller.value),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeInLeft(
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "NEXTGEN",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              letterSpacing: 2),
                        ),
                        Text(
                          "ROYAL TRANSPORT",
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                  FadeInRight(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white),
                        onPressed: _showNotificationSettings,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 130,
            left: 24,
            child: FadeInDown(
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome, Chief",
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
                  Text("WHERE TO\nEXPLORE?",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.1)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final bounce = math.sin(_controller.value * 60) * 0.8;
                return Transform.translate(
                  offset: Offset(0, bounce),
                  child: Center(child: _buildRealisticBus()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealisticBus() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 300,
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(15),
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 20)),
              BoxShadow(
                  color: AppColors.primary.withOpacity(0.2), blurRadius: 20),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 25,
                left: 0,
                right: 0,
                child: Container(
                  height: 15,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Color(0x806D28D9)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15, left: 60),
                child: Row(
                  children: List.generate(
                      5,
                      (index) => Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10),
                            ),
                          )),
                ),
              ),
              Positioned(
                left: 2,
                top: 15,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F172A),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        bottomRight: Radius.circular(10)),
                  ),
                ),
              ),
              const Positioned(
                bottom: 28,
                left: 80,
                child: Text("KILIMANJARO ROYAL EXPRESS",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 240,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildAlloyWheel(), _buildAlloyWheel()],
          ),
        ),
      ],
    );
  }

  Widget _buildAlloyWheel() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: -_controller.value * 30 * math.pi,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.grey.shade800, width: 3),
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(
                      6,
                      (i) => Transform.rotate(
                            angle: i * 60 * math.pi / 180,
                            child: Container(
                                width: 2,
                                height: 28,
                                color: Colors.grey.shade600),
                          )),
                  Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Colors.grey, shape: BoxShape.circle)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Transform.translate(
            offset: const Offset(0, -60),
            child: FadeInUp(child: const SearchCard()),
          ),
          _buildQuickActionRow(),
          const SizedBox(height: 32),
          _buildSectionHeader("MAJESTIC ROUTES", "VIEW ALL"),
          const SizedBox(height: 20),
          _buildMajesticRoutes(),
          const SizedBox(height: 40),
          _buildLuxuryPromo(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickActionRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickAction(Icons.history_rounded, "History"),
        _quickAction(Icons.stars_rounded, "Royal Club"),
        _quickAction(Icons.location_on_rounded, "Live Track"),
        _quickAction(Icons.support_agent_rounded, "Concierge"),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(icon, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5)),
        Text(action,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMajesticRoutes() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 20),
        itemBuilder: (context, index) => Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                    child: Icon(Icons.landscape_rounded,
                        color: Colors.white, size: 50)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("DAR - ARUSHA",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("FROM TZS 35,000",
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryPromo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFB8860B), Color(0xFFDAA520)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ROYAL VVIP EXPERIENCE",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const Text(
              "Enjoy gourmet meals and personal iPad TV on our VVIP seats.",
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
                color: Colors.black, borderRadius: BorderRadius.circular(15)),
            child: const Text("EXPLORE VVIP",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class MajesticNaturePainter extends CustomPainter {
  final double progress;
  MajesticNaturePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final roadY = size.height - 100;

    paint.color = Colors.white.withOpacity(0.3);
    for (int i = 0; i < 30; i++) {
      double x = (math.sin(i * 123.45) * 0.5 + 0.5) * size.width;
      double y = (math.cos(i * 543.21) * 0.5 + 0.5) * (roadY - 100);
      canvas.drawCircle(Offset(x, y), 1, paint);
    }

    paint.color = Colors.white.withOpacity(0.02);
    for (int i = -1; i < 2; i++) {
      double x = (i + (progress * 0.05) % 1.0) * size.width;
      final path = Path()
        ..moveTo(x, roadY)
        ..lineTo(x + size.width * 0.4, roadY - 150)
        ..lineTo(x + size.width * 0.7, roadY - 80)
        ..lineTo(x + size.width, roadY)
        ..close();
      canvas.drawPath(path, paint);
    }

    paint.color = const Color(0xFF1E293B);
    canvas.drawRect(Rect.fromLTWH(0, roadY, size.width, 100), paint);

    paint.color = Colors.white.withOpacity(0.3);
    double dashW = 80;
    double dashS = 80;
    double offset = (progress * 2500) % (dashW + dashS);
    for (double x = -dashW; x < size.width + dashW; x += (dashW + dashS)) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x + offset, roadY + 48, dashW, 4),
              const Radius.circular(2)),
          paint);
    }

    paint.color = Colors.white.withOpacity(0.05);
    for (int i = 0; i < 20; i++) {
      double x = (i * 80 + (progress * 2500)) % (size.width + 80) - 40;
      canvas.drawRect(Rect.fromLTWH(x, roadY - 20, 2, 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant MajesticNaturePainter oldDelegate) => true;
}
