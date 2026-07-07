import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../controllers/auth_controller.dart';

/// [AdminHomePage] merupakan dashboard pusat kendali untuk administrator sistem iCoass.
/// Menggunakan pola navigasi GetX untuk manajemen transisi antar modul administrasi.
class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: AppBar(
        title: const Text(
          'iCoass Admin Center',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout, color: Colors.white),
        //     tooltip: 'Logout',
        //     onPressed: () => Get.find<AuthController>().logout(),
        //   ),
        // ],
      ),
      body: Column(
        children: [
          // Header Stats & Identity
          _buildAdminHeader(),

          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daftar Menu",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ),
          ),

          // Menu Grid untuk Manajemen Data Skripsi
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              children: [
                _buildMenuCard(
                  'Manajemen Akun',
                  Icons.people_alt,
                  Colors.blue,
                  () {
                    Get.toNamed('/patient-management');
                  },
                ),
                // _buildMenuCard('Riwayat Diagnosa', Icons.history_edu, Colors.orange, () {
                //   Get.toNamed('/diagnosis-history');
                // }),
                // Navigasi ke fitur Manajemen Rumah Sakit yang baru dibuat
                _buildMenuCard(
                  'Manajemen Rumah Sakit',
                  Icons.local_hospital,
                  Colors.red,
                  () {
                    Get.toNamed('/admin-hospital');
                  },
                ),
                // _buildMenuCard(
                //   'Manajemen Basis Aturan',
                //   Icons.rule_folder,
                //   Colors.green,
                //   () {
                //     // Navigasi ke manajemen rule Naive Bayes
                //   },
                // ),
                _buildMenuCard(
                  'Chat Pasien',
                  Icons.chat_bubble_rounded,
                  Colors.purple,
                  () {
                    // Navigasi ke statistik data
                    Get.toNamed('/admin-chat-list');
                  },
                ),
                _buildMenuCard(
                  'Antrian Chat',
                  Icons.queue,
                  Colors.blueGrey,
                  () {
                    // Pengaturan API / Admin
                    Get.toNamed('/admin-chat-queue');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      // child: Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     const Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         Text("Kelola Sistem iCoass",
      //           style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      //         // SizedBox(height: 5),
      //         // Text("Administrator Mode",
      //         //   style: TextStyle(color: Colors.white70, fontSize: 14)),
      //       ],
      //     ),
      //     const CircleAvatar(
      //       radius: 30,
      //       backgroundColor: Colors.white24,
      //       child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 35),
      //     )
      //   ],
      // ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 30,
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
