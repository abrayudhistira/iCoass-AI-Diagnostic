import 'package:flutter/material.dart';
import 'colors.dart';

class SymptomCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<Map<String, String>> symptoms;

  const SymptomCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.symptoms,
  });
}

final List<SymptomCategory> symptomCategories = [
  SymptomCategory(
    id: 'kondisi_gusi',
    title: 'Kondisi Gusi',
    subtitle: 'Tampilan & fisik gusi',
    icon: Icons.emergency_rounded,
    accentColor: AppColors.primary,
    symptoms: [
      {"code": "BG001", "name": "Gusi kemerahan"},
      {"code": "BG002", "name": "Gusi bengkak"},
      {"code": "BG003", "name": "Gusi mengkilat"},
      {"code": "BG004", "name": "Gusi mudah berdarah"},
      {"code": "BG005", "name": "Gusi terasa lunak"},
      {"code": "BG006", "name": "Gusi bertangkai"},
      {"code": "BG007", "name": "Gusi turun"},
    ],
  ),
  SymptomCategory(
    id: 'sensasi_gusi',
    title: 'Sensasi Gusi',
    subtitle: 'Rasa sakit & ketidaknyamanan',
    icon: Icons.sentiment_dissatisfied_rounded,
    accentColor: const Color(0xFFFF9800),
    symptoms: [
      {"code": "BS001", "name": "Gusi tidak ada rasa sakit"},
      {"code": "BS002", "name": "Gusi terasa sakit"},
      {"code": "BS003", "name": "Gusi terasa gatal"},
      {"code": "BS004", "name": "Sakit atau tidak nyaman saat mengunyah"},
    ],
  ),
  SymptomCategory(
    id: 'tanda_fisik',
    title: 'Tanda Fisik Lain',
    subtitle: 'Karang gigi, demam, bengkak',
    icon: Icons.warning_amber_rounded,
    accentColor: const Color(0xFFE91E63),
    symptoms: [
      {"code": "BP001", "name": "Terdapat karang gigi"},
      {"code": "BP002", "name": "Gigi goyah"},
      {"code": "BP003", "name": "Bau mulut"},
      {"code": "BP004", "name": "Demam"},
      {"code": "BP005", "name": "Bengkak dan nyeri tekan pada pipi/bawah telinga"},
      {"code": "BP006", "name": "Gigi berlubang/patah di dekat gusi yang dikeluhkan"},
      {"code": "BP007", "name": "Ada benjolan kecil di dekat gusi yang sakit"},
      {"code": "BP008", "name": "Gigi terlihat panjang"},
      {"code": "BP009", "name": "Akar gigi terlihat"},
    ],
  ),
  SymptomCategory(
    id: 'riwayat',
    title: 'Riwayat & Kebiasaan',
    subtitle: 'Penyakit penyerta & kebiasaan',
    icon: Icons.assignment_rounded,
    accentColor: const Color(0xFF4CAF50),
    symptoms: [
      {"code": "BT001", "name": "Penyakit gula (DM)"},
      {"code": "BT002", "name": "Hipertensi"},
      {"code": "BT003", "name": "Konsumsi obat pil KB / kortikosteroid / antikejang"},
      {"code": "BT004", "name": "Penyakit menular seperti HIV, TBC"},
      {"code": "BT005", "name": "Kebiasaan merokok"},
      {"code": "BT006", "name": "Sedang hamil"},
      {"code": "BT007", "name": "Sedang memakai behel"},
    ],
  ),
  SymptomCategory(
    id: 'gigi_permanen',
    title: 'Kondisi Gigi Permanen',
    subtitle: 'Status gigi dewasa',
    icon: Icons.health_and_safety_rounded,
    accentColor: const Color(0xFF7E57C2),
    symptoms: [
      {"code": "AP001", "name": "Gigi permanen tidak berlubang"},
      {"code": "AP002", "name": "Gigi permanen berlubang"},
      {"code": "AP003", "name": "Gigi permanen patah"},
      {"code": "AP004", "name": "Gigi permanen pernah terbentur keras"},
      {"code": "AP005", "name": "Gigi permanen tidak tumbuh sempurna"},
      {"code": "AP006", "name": "Gigi permanen hanya tersisa akar"},
      {"code": "AP007", "name": "Satu atau beberapa gigi permanen hilang"},
      {"code": "AP008", "name": "Semua gigi hilang"},
      {"code": "AP009", "name": "Gigi tidak rapi / tumpang tindih / ada celah"},
    ],
  ),
  SymptomCategory(
    id: 'gigi_susu',
    title: 'Kondisi Gigi Susu',
    subtitle: 'Status gigi anak',
    icon: Icons.child_care_rounded,
    accentColor: const Color(0xFF00ACC1),
    symptoms: [
      {"code": "AS001", "name": "Gigi susu dan gigi permanen tumpang tindih"},
      {"code": "AS002", "name": "Gigi susu lepas belum ada gigi permanen"},
      {"code": "AS003", "name": "Gigi susu tidak berlubang"},
      {"code": "AS004", "name": "Gigi susu berlubang"},
      {"code": "AS005", "name": "Gigi susu patah"},
      {"code": "AS006", "name": "Gigi susu pernah terbentur"},
      {"code": "AS007", "name": "Gigi susu hanya tersisa akar"},
    ],
  ),
  SymptomCategory(
    id: 'nyeri',
    title: 'Karakteristik Nyeri',
    subtitle: 'Jenis dan pola rasa sakit',
    icon: Icons.local_fire_department_rounded,
    accentColor: const Color(0xFFFFA000),
    symptoms: [
      {"code": "AN017", "name": "Tidak ada rasa nyeri"},
      {"code": "AN018", "name": "Nyeri singkat"},
      {"code": "AN019", "name": "Nyeri kemasukan makanan"},
      {"code": "AN020", "name": "Nyeri saat makan/minum dingin"},
      {"code": "AN021", "name": "Nyeri saat makan/minum panas"},
      {"code": "AN022", "name": "Nyeri hanya ada di gigi tersebut"},
      {"code": "AN023", "name": "Nyeri tiba-tiba"},
      {"code": "AN024", "name": "Nyeri berdenyut"},
      {"code": "AN025", "name": "Nyeri menetap dan menyebar ke kepala"},
      {"code": "AN026", "name": "Nyeri diperparah saat tidur"},
      {"code": "AN027", "name": "Sakit saat mengunyah"},
      {"code": "AN028", "name": "Sakit atau sulit saat membuka mulut"},
      {"code": "AN029", "name": "Sudah diberi obat tetapi tetap nyeri"},
      {"code": "AN030", "name": "Dulu nyeri hebat tapi sekarang tidak"},
    ],
  ),
  SymptomCategory(
    id: 'warna_kondisi',
    title: 'Warna & Kondisi Lanjut',
    subtitle: 'Perubahan warna & gejala lainnya',
    icon: Icons.visibility_rounded,
    accentColor: const Color(0xFFAB47BC),
    symptoms: [
      {"code": "AW031", "name": "Warna gigi normal"},
      {"code": "AW032", "name": "Terdapat kehitaman/keabuan/kecoklatan di permukaan gigi"},
      {"code": "AW033", "name": "Warna gigi berubah lebih gelap atau abu-abu"},
      {"code": "AL035", "name": "Gusi normal"},
      {"code": "AL036", "name": "Gusi bengkak dan kemerahan"},
      {"code": "AL037", "name": "Gusi turun"},
      {"code": "AL038", "name": "Ada benjolan kecil di dekat gusi yang sakit"},
      {"code": "AL039", "name": "Gigi goyah"},
      {"code": "AL040", "name": "Tidak nyaman saat mengunyah"},
      {"code": "AL041", "name": "Bengkak dan nyeri tekan pada pipi/bawah telinga"},
      {"code": "AL042", "name": "Sebelumnya ada demam"},
      {"code": "AL043", "name": "Demam"},
      {"code": "AL044", "name": "Gula darah tinggi"},
      {"code": "AL045", "name": "Hipertensi / tekanan darah tinggi"},
      {"code": "AL046", "name": "Jantung"},
      {"code": "AL047", "name": "Asam lambung"},
      {"code": "AL048", "name": "Penyakit menular (HIV)"},
    ],
  ),
];

List<String> getSymptomNames(List<String> codes) {
  List<String> names = [];
  for (var code in codes) {
    for (var category in symptomCategories) {
      for (var symptom in category.symptoms) {
        if (symptom['code'] == code) {
          if (symptom['name'] != null) {
            names.add(symptom['name']!);
          }
          break;
        }
      }
    }
  }
  return names;
}
