import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unitrack/screens/login_screen.dart';
import 'package:unitrack/services/send_location_service.dart';
import 'package:unitrack/widgets/assign_buggy_dialog.dart';
import 'package:unitrack/widgets/map.dart';
import 'package:unitrack/config/app_colors.dart'; // Import your colors file

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final user = Supabase.instance.client.auth.currentUser;

  String? buggyNumber;
  String? buggyId;
  String? driverName;
  bool isActive = false;
  bool loading = true;

  LocationSender? locationSender;

  @override
  void initState() {
    super.initState();
    fetchDriverAndBuggyInfo();
  }

  Future<void> fetchDriverAndBuggyInfo() async {
    try {
      final response = await _supabase
          .from('drivers')
          .select('name')
          .eq('id', user!.id)
          .maybeSingle();

      if (response != null) {
        driverName = response['name'] as String?;
        buggyNumber = null;

        print('Driver name from database: $driverName');

        if (buggyNumber != null && buggyNumber!.isNotEmpty) {
          final buggyResp = await _supabase
              .from('buggies')
              .select('id, status')
              .eq('buggy_number', buggyNumber!)
              .maybeSingle();

          if (buggyResp != null) {
            buggyId = buggyResp['id'];
            isActive = buggyResp['status'] == 'active';

            if (isActive) {
              locationSender = LocationSender(buggyId!);
              locationSender!.start();
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching driver/buggy info: $e');
    }

    setState(() => loading = false);

    if (buggyNumber == null || buggyNumber!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        assignNewBuggy();
      });
    }
  }

  Future<void> toggleActive(bool value) async {
    if (buggyId == null) return;

    setState(() => isActive = value);

    try {
      await _supabase
          .from('buggies')
          .update({'status': value ? 'active' : 'inactive'})
          .eq('id', buggyId!);

      if (value) {
        locationSender = LocationSender(buggyId!);
        locationSender!.start();
      } else {
        locationSender?.stop();
      }
    } catch (e) {
      print('Error toggling active status: $e');
      // Revert the state if there's an error
      setState(() => isActive = !value);
    }
  }

  Future<void> assignNewBuggy() async {
    final result = await showDialog(
      context: context,
      builder: (_) => const AssignBuggyDialog(),
    );

    if (result != null) {
      buggyNumber = result;

      final buggyResp = await _supabase
          .from('buggies')
          .select('id, status')
          .eq('buggy_number', buggyNumber!)
          .maybeSingle();

      if (buggyResp != null) {
        buggyId = buggyResp['id'];
        isActive = buggyResp['status'] == 'active';

        if (isActive) {
          locationSender = LocationSender(buggyId!);
          locationSender!.start();
        }
      }

      setState(() {});
    }
  }

  Future<void> logout() async {
    locationSender?.stop();
    await _supabase.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    locationSender?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryBlue, AppColors.primaryBlueDark],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                SizedBox(height: 24),
                Text(
                  'Loading your dashboard...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    String displayName = driverName?.isNotEmpty == true ? driverName! : 'Driver';
    String formattedName = displayName[0].toUpperCase() + displayName.substring(1);

    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: _buildAppBar(formattedName),
      body: _buildDashboardContent(),
    );
  }

  PreferredSizeWidget _buildAppBar(String formattedName) {
    return AppBar(
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hello $formattedName",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          const Text(
            "Ready to drive?",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primaryBlue,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryBlueLight, AppColors.primaryBlueDark],
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: logout,
            tooltip: 'Logout',
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBuggyAssignmentCard(),
            const SizedBox(height: 16),
            if (buggyNumber != null && buggyNumber!.isNotEmpty) ...[
              _buildLocationTrackingCard(),
              const SizedBox(height: 16),
              _buildMapContainer(),
            ] else
              _buildNoBuggyAssignedCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBuggyAssignmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Assigned Vehicle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, color: AppColors.accentTeal, size: 20),
                  onPressed: assignNewBuggy,
                  tooltip: 'Change Vehicle',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: buggyNumber != null && buggyNumber!.isNotEmpty
                  ? AppColors.successGreen.withOpacity(0.1)
                  : AppColors.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: buggyNumber != null && buggyNumber!.isNotEmpty
                    ? AppColors.successGreen.withOpacity(0.3)
                    : AppColors.warningOrange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: buggyNumber != null && buggyNumber!.isNotEmpty
                        ? AppColors.successGreen
                        : AppColors.warningOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    buggyNumber != null && buggyNumber!.isNotEmpty
                        ? Icons.check_circle_rounded
                        : Icons.warning_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buggyNumber ?? 'No vehicle assigned',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: buggyNumber != null && buggyNumber!.isNotEmpty
                              ? AppColors.successGreen
                              : AppColors.warningOrange,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        buggyNumber != null && buggyNumber!.isNotEmpty
                            ? 'Vehicle ready for service'
                            : 'Please assign a vehicle to continue',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTrackingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.successGreen.withOpacity(0.1)
                  : AppColors.neutralGray.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isActive ? Icons.location_on_rounded : Icons.location_off_rounded,
              color: isActive ? AppColors.successGreen : AppColors.neutralGray,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location Tracking',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive
                      ? 'Currently tracking your location'
                      : 'Location tracking is disabled',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: toggleActive,
            activeColor: Colors.white,
            activeTrackColor: AppColors.successGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.neutralGray.withOpacity(0.3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildMapContainer() {
    return Container(
      width: double.infinity,
      height: 400, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: isActive
            ? UniversityMapWidget(isActive: isActive)
            : _buildInactiveState(),
      ),
    );
  }

  Widget _buildNoBuggyAssignedCard() {
    return Container(
      width: double.infinity,
      height: 400, // Fixed height to prevent overflow
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.warningOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_outlined,
              size: 48,
              color: AppColors.warningOrange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Vehicle Assigned',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Please assign a vehicle to start tracking your location and begin your route.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accentTeal, AppColors.accentTealLight],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: assignNewBuggy,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Assign Vehicle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.neutralGray.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_off_rounded,
              size: 48,
              color: AppColors.neutralGray,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Location Tracking Disabled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Turn on location tracking to see your position on the map and start your route.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.successGreen, AppColors.successGreenLight],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successGreen.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => toggleActive(true),
              icon: const Icon(Icons.location_on_rounded, color: Colors.white),
              label: const Text(
                'Enable Tracking',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}