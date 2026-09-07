import 'package:flutter/material.dart';
import 'package:trashtocash/helpers/driver_helper.dart';
import 'package:trashtocash/models/driver_model.dart';
import 'package:trashtocash/screens/home.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  void _showVehicleChangeDialog(BuildContext context, DriverProfileModel profile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2822) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pilih Jenis Kendaraan Armada',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DriverVehicleType.values.map((v) {
            final isSelected = profile.vehicleType == v;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(v.icon, color: const Color(0xFF0D6938)),
              title: Text(
                v.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              subtitle: Text(
                'Kapasitas maks: ${v.maxCapacityKg.toStringAsFixed(0)} kg',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Color(0xFF0D6938))
                  : null,
              onTap: () {
                final updated = profile.copyWith(vehicleType: v);
                DriverHelper.instance.updateDriverProfile(updated);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _switchToUserMode() {
    DriverHelper.instance.isDriverModeActive.value = false;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeTrashToCash()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<DriverProfileModel>(
      valueListenable: DriverHelper.instance.profileNotifier,
      builder: (context, profile, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Driver Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A241E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFF0D6938).withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person,
                        color: Color(0xFF0D6938),
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Color(0xFF0D6938), size: 18),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID Mitra: ${profile.id} • Platinum Driver',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 12),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${profile.rating} (${profile.totalReviews} Ulasan)',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Operational Radius Setting
              Text(
                'Pengaturan Jangkauan Tugas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A241E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.radar, color: Color(0xFF0D6938), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Radius Radar Order',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Text(
                          '${profile.operationalRadiusKm.toStringAsFixed(0)} KM',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D6938),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: profile.operationalRadiusKm,
                      min: 1.0,
                      max: 15.0,
                      divisions: 14,
                      activeColor: const Color(0xFF0D6938),
                      onChanged: (val) {
                        final updated = profile.copyWith(operationalRadiusKm: val);
                        DriverHelper.instance.updateDriverProfile(updated);
                      },
                    ),
                    Text(
                      'Hanya menampilkan orderan penjemputan warga dalam radius ini.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Vehicle & Fleet Details
              Text(
                'Informasi Kendaraan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A241E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(profile.vehicleType.icon, color: const Color(0xFF0D6938)),
                      title: Text(
                        profile.vehicleType.label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Pelat: ${profile.vehiclePlate} • Maks ${profile.vehicleType.maxCapacityKg.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                      trailing: TextButton(
                        child: const Text(
                          'Ubah',
                          style: TextStyle(
                            color: Color(0xFF0D6938),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showVehicleChangeDialog(context, profile),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Verification Documents
              Text(
                'Dokumen & Verifikasi Mitra',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildDocItem('KTP Elektronik Mitra', 'Terverifikasi (Dukcapil)', isDark),
              const SizedBox(height: 8),
              _buildDocItem('SIM C Aktif', 'Terverifikasi (Berlaku s/d 2028)', isDark),
              const SizedBox(height: 8),
              _buildDocItem('STNK Kendaraan', 'Terverifikasi (Pajak Aktif)', isDark),
              const SizedBox(height: 24),

              // Switch Mode Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF0D6938)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz, color: Color(0xFF0D6938)),
                  label: const Text(
                    'Beralih ke Mode Pengguna (Warga)',
                    style: TextStyle(
                      color: Color(0xFF0D6938),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: _switchToUserMode,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocItem(String title, String status, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A241E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF0D6938), size: 14),
              const SizedBox(width: 4),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D6938),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
