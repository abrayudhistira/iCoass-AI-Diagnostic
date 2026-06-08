import '../../domain/entities/hospital_entity.dart';

/// [HospitalModel] mengimplementasikan logika transformasi data dari JSON ke Entity.
/// Model ini dirancang khusus untuk menangani tipe data DECIMAL dari MySQL/Sequelize
/// yang seringkali dikirimkan sebagai String untuk menjaga presisi 8 digit desimal.
class HospitalModel extends HospitalEntity {
  const HospitalModel({
    super.id,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.phone,
    super.description,
    super.imageUrl,
  });

  /// Factory method untuk memetakan JSON response ke objek [HospitalModel].
  /// Menggunakan metode parsing eksplisit guna mencegah pembulatan otomatis oleh Dart.
  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] as String? ?? 'Tanpa Nama',
      address: json['address'] as String? ?? 'Alamat tidak tersedia',
      
      // Menerapkan helper _parseCoordinate untuk menjamin akurasi geospasial
      latitude: _parseCoordinate(json['latitude']),
      longitude: _parseCoordinate(json['longitude']),
      
      phone: json['phone']?.toString() ?? '--',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  /// Fungsi helper untuk mengonversi nilai koordinat secara aman.
  /// Mendukung input berupa num (int/double) maupun String dari API.
  static double _parseCoordinate(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Mengonversi model kembali ke JSON. 
  /// Catatan: Untuk pengiriman ke server, preferensi menggunakan toStringAsFixed(8) di Repository.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'description': description,
      'image_url': imageUrl,
    };
  }
}
