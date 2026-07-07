import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';

class AdminMenuSection extends StatelessWidget {
  const AdminMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _buildMenuCard(
          'Manajemen Akun',
          Icons.people_alt,
          Colors.blue,
          () => Get.toNamed('/patient-management'),
        ),
        _buildMenuCard(
          'Manajemen Rumah Sakit',
          Icons.local_hospital,
          Colors.red,
          () => Get.toNamed('/admin-hospital'),
        ),
        _buildMenuCard(
          'Chat Pasien',
          Icons.chat_bubble_rounded,
          Colors.purple,
          () => Get.toNamed('/admin-chat-list'),
        ),
        _buildMenuCard(
          'Antrian Chat',
          Icons.queue,
          Colors.blueGrey,
          () => Get.toNamed('/admin-chat-queue'),
        ),
      ],
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